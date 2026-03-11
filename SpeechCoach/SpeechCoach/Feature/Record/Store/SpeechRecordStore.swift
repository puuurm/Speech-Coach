//
//  SpeechRecordStore.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/26/25.
//

import Foundation
import Combine
import CoreData

final class SpeechRecordStore: ObservableObject {
    @Published private(set) var records: [SpeechRecord] = []
    
    private var context: NSManagedObjectContext
    private let maxRecentCount: Int = 20
    private let crashLogger: CrashLogging
    
    init(
        context: NSManagedObjectContext,
        crashLogger: CrashLogging = NoOptionsCrashLogger()
    ) {
        self.context = context
        self.crashLogger = crashLogger
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.context.automaticallyMergesChangesFromParent = true
        reload()
    }
    
    func record(with id: UUID) -> SpeechRecord? {
        var result: SpeechRecord?
        context.performAndWait {
            do {
                guard let entity = try fetchRecordEntity(id: id) else {
                    result = nil
                    return
                }
                result = SpeechRecordMapper.toDomain(entity)
            } catch {
                assertionFailure("❌ record(with:) fetch failed: \(error)")
                result = nil
            }
        }
        return result
    }
    
    func metrics(with recordID: UUID) -> SpeechMetrics? {
        var result: SpeechMetrics?
        context.performAndWait {
            do {
                guard let entity = try fetchMetricsEntity(recordID: recordID) else {
                    result = nil
                    return
                }
                result = SpeechMetricsMapper.toDomain(entity)
            } catch {
                assertionFailure("❌ metrics(with:) fetch failed: \(error)")
                result = nil
            }
        }
        return result
    }
    
    func upsertBundle(
        record: SpeechRecord,
        metrics: SpeechMetrics?
    ) {
        context.perform {
            do {
                let recordEntity = try self.fetchOrCreateRecordEntity(id: record.id)
                SpeechRecordMapper.apply(
                    record,
                    to: recordEntity,
                    context: self.context
                )
                if let metrics {
                    let metricsEntity = recordEntity.metrics ?? SpeechMetricsEntity(context: self.context)
                    metricsEntity.record = recordEntity
                    recordEntity.metrics = metricsEntity
                    SpeechMetricsMapper.apply(
                        metrics,
                        to: metricsEntity
                    )
                    recordEntity.summaryWPM = Int32(metrics.wordsPerMinute)
                    recordEntity.summaryFillerCount = Int32(metrics.fillerCount)
                    recordEntity.metricsGeneratedAt = metrics.generatedAt
                }
                try self.context.save()
            } catch {
                self.crashLogger.setValue(record.id.uuidString, forKey: "record_id")
                self.crashLogger.setValue("upsertBundle", forKey: "store_action")
                self.crashLogger.record(error)
                assertionFailure("❌ upsertBundle failed: \(error)")
            }
        }
    }
    
    func saveCoachingMemo(recordID: UUID, memo: String) throws {
        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let record = try fetchOrCreateRecordEntity(id: recordID)
            let note = try fetchOrCreateNote(for: record)
            note.coachingMemo = trimmed.isEmpty ? nil : trimmed
            note.updatedAt = Date()
            try context.save()
            objectWillChange.send()
        } catch {
            crashLogger.setValue(recordID.uuidString, forKey: "record_id")
            crashLogger.setValue("saveCoachingMemo", forKey: "store_action")
            crashLogger.log("SpeechRecordStore: memo save failed length=\(trimmed.count)")
            crashLogger.record(error)

            context.rollback()
            throw error
        }
  
    }
    
    func loadRecentRecords(limit: Int = 20) -> [SpeechRecord] {
        var results: [SpeechRecord] = []
        context.performAndWait {
            do {
                let req = SpeechRecordEntity.fetchRequest()
                req.fetchLimit = limit
                req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                // ✅ 분석 완료만:
                // req.predicate = NSPredicate(format: "metricsGeneratedAt != nil")

                let entities = try self.context.fetch(req)
                results = entities.map(SpeechRecordMapper.toDomain)
            } catch {
                assertionFailure("❌ loadRecentRecords failed: \(error)")
            }
        }
        return results
    }
    
    func loadBundle(
        recordID: UUID
    ) -> (record: SpeechRecord, metrics: SpeechMetrics?)? {
        var result: (SpeechRecord, SpeechMetrics?)?
        context.performAndWait {
            do {
                guard let recordEntity = try fetchRecordEntity(id: recordID)
                else { return }
                let record = SpeechRecordMapper.toDomain(recordEntity)
                let metrics = recordEntity.metrics.flatMap(SpeechMetricsMapper.toDomain)
                result = (record, metrics)
            } catch {
                assertionFailure("❌ loadBundle failed: \(error)")
            }
        }
        return result
    }
    
    func add(_ record: SpeechRecord) {
        context.perform {
            do {
                let entity = try self.fetchRecordEntity(id: record.id) ?? SpeechRecordEntity(context: self.context)
                SpeechRecordMapper.apply(record, to: entity, context: self.context)
                try self.saveContext()
                self.reload()
            } catch {
                assertionFailure("❌ add failed: \(error)")
            }
        }
    }
    
    func updateNotes(
        for id: UUID,
        intro: String,
        strenghts: String,
        improvements: String,
        nextStep: String,
        checklist: String? = nil
    ) {
        let context = self.context
        
        context.perform {
            do {
                guard let entity = try self.fetchRecordEntity(id: id) else { return }
                let noteEntity: SpeechRecordNoteEntity
                if let existing = entity.note {
                    noteEntity = existing
                } else {
                    let creadted = SpeechRecordNoteEntity(context: context)
                    creadted.record = entity
                    entity.note = creadted
                    noteEntity = creadted
                }
                
                SpeechRecordNoteMapper.apply(
                    SpeechRecord.Note(
                        intro: intro,
                        strengths: strenghts,
                        improvements: improvements,
                        nextStep: nextStep,
                        checklist: checklist
                    ),
                    to: noteEntity
                )
                print("Updated notes for record:", id)
            } catch {
                assertionFailure("❌ updateNotes failed: \(error)")
            }
        }
    }
    
    @MainActor
    func persist() async throws {
        let context = self.context
        
        do {
            try await context.perform {
                guard context.hasChanges else { return }
                try context.save()
            }
            self.reload()
        } catch {
            crashLogger.setValue("persist", forKey: "store_action")
            crashLogger.log("SpeechRecordStore: persist failed")
            crashLogger.record(error)
            context.rollback()
            throw error
        }
    }
    
    func updateQualitative(for id: UUID, metrics: QualitativeMetrics) {
        context.perform {
            do {
                guard let entity = try self.fetchRecordEntity(id: id) else { return }

                let insightEntity = entity.insight ?? SpeechRecordInsightEntity(context: self.context)
                insightEntity.record = entity
                entity.insight = insightEntity

                SpeechRecordInsightMapper.apply(metrics, to: insightEntity)
            } catch {
                assertionFailure("❌ updateQualitative failed: \(error)")
            }
        }
    }
    
    func previousRecord(before id: UUID) -> SpeechRecord? {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return nil }
        let nextIndex = index + 1
        guard records.indices.contains(nextIndex) else { return nil }
        return records[nextIndex]
    }
    
    func updateStudentName(
        recordID: UUID,
        studentName: String?
    ) async throws {
        try await context.perform {
            let request = SpeechRecordEntity.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", recordID as CVarArg)
            
            guard let entity = try self.context.fetch(request).first else {
                throw NSError(
                    domain: "SpeechRecordStore",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "SpeechRecord not found"]
                )
            }
            
            let oldValue = entity.studentName
            entity.studentName = studentName
            
            do {
                try self.context.save()
            } catch {
                self.context.rollback()
                entity.studentName = oldValue
                throw error
            }
        }
    }
    
    func delete(recordID: UUID) {
        context.perform {
            do {
                if let entity = try self.fetchRecordEntity(id: recordID) {
                    self.context.delete(entity)
                    try self.context.save()
                    self.reload()
                }
            } catch {
                assertionFailure("❌ delete failed: \(error)")
            }
        }
    }
    
    func delete(_ record: SpeechRecord) {
        context.perform {
            do {
                guard let entity = try self.fetchRecordEntity(id: record.id) else { return }
                self.context.delete(entity)
                try self.saveContext()
                self.reload()
                print("🗑 Deleted record:", record.id)
            } catch {
                assertionFailure("❌ delete failed: \(error)")
            }
        }
    }
    
    func deleteAll() {
        context.perform {
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SpeechRecordEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                let result = try self.context.execute(deleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                }

                try self.saveContext()
                self.reload()
                print("🧹 Cleared all records")
            } catch {
                assertionFailure("❌ deleteAll failed: \(error)")
            }
        }
    }
    
    func clear() {
        deleteAll()
    }
    
    private func reload() {
        context.perform {
            do {
                let request = SpeechRecordEntity.fetchRequest()
                request.sortDescriptors = [
                    NSSortDescriptor(key: "createdAt", ascending: false)
                ]
                request.fetchLimit = self.maxRecentCount
                
                let entities = try self.context.fetch(request)
                self.records = entities.map { SpeechRecordMapper.toDomain($0) }
            } catch {
                assertionFailure("❌ reload failed: \(error)")
            }
        }
    }
    
    private func fetchRecordEntity(id: UUID) throws -> SpeechRecordEntity? {
        let request = SpeechRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func fetchOrCreateRecordEntity(id: UUID) throws -> SpeechRecordEntity {
        if let existing = try fetchRecordEntity(id: id) {
            return existing
        }
        let entity = SpeechRecordEntity(context: context)
        entity.id = id
        return entity
    }
    
    private func fetchOrCreateNote(for record: SpeechRecordEntity) throws -> SpeechRecordNoteEntity {
        if let existing = record.note { return existing }

        let note = SpeechRecordNoteEntity(context: context)

        note.intro = ""
        note.strengths = ""
        note.improvements = ""
        note.nextStep = ""
        note.checklist = ""
        note.coachingMemo = nil

        note.updatedAt = Date()

        note.record = record
        record.note = note

        return note
    }

    private func fetchMetricsEntity(recordID: UUID) throws -> SpeechMetricsEntity? {
        let request = SpeechMetricsEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "record.id == %@", recordID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "generatedAt", ascending: false)]
        return try context.fetch(request).first
    }
    
    func coachingMemo(with recordID: UUID) -> String {
        var result = ""
        context.performAndWait {
            do {
                guard let entity = try self.fetchRecordEntity(id: recordID) else { return }
                result = entity.note?.coachingMemo ?? ""
            } catch {
                assertionFailure("❌ coachingMemo(with:) fetch failed: \(error)")
            }
        }
        return result
    }
    
    func updateVideoRelativePath(recordID: UUID, relativePath: String) {
        context.perform {
            do {
                guard let entity = try self.fetchRecordEntity(id: recordID) else {
                    assertionFailure("❌ Record not found: \(recordID)")
                    return
                }
                entity.videoRelativePath = relativePath
                try self.saveContext()
                self.reload()
            } catch {
                assertionFailure("❌ updateVideoRelativePath failed: \(error)")
            }
        }
    }

    private func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    private func clog(_ message: String) {
        crashLogger.log("SpeechRecordStore: \(message)")
    }
}

extension SpeechRecordStore: SpeechRecordPersisting {}

extension SpeechRecordStore {

    func upsertDailyFocus(
        date: Date,
        text: String,
        recordID: UUID?
    ) {
        let day = Calendar.current.startOfDay(for: date)
        let now = Date()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }

        context.perform {
            do {
                let req: NSFetchRequest<DailyFocusEntity> = DailyFocusEntity.fetchRequest()
                req.fetchLimit = 1

                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(60 * 60 * 24)
                req.predicate = NSPredicate(format: "date >= %@ AND date < %@", day as NSDate, nextDay as NSDate)

                let entity = try self.context.fetch(req).first ?? DailyFocusEntity(context: self.context)

                if entity.id == UUID() {
                }

                if entity.objectID.isTemporaryID {
                    entity.id = UUID()
                    entity.date = day
                    entity.isDone = false
                }

                entity.text = trimmed
                entity.recordID = recordID
                entity.updatedAt = now

                try self.context.save()
            } catch {
                self.crashLogger.setValue("upsertDailyFocus_failed", forKey: "daily_focus")
//                self.crashLogger.record(error: error)
            }
        }
    }

    func fetchDailyFocus(for date: Date) -> DailyFocus? {
        let day = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(60 * 60 * 24)

        var result: DailyFocus?

        context.performAndWait {
            do {
                let req: NSFetchRequest<DailyFocusEntity> = DailyFocusEntity.fetchRequest()
                req.fetchLimit = 1
                req.predicate = NSPredicate(format: "date >= %@ AND date < %@", day as NSDate, nextDay as NSDate)
                req.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

                if let e = try self.context.fetch(req).first,
                    let id = e.id,
                    let date = e.date,
                    let text = e.text,
                    let recordID = e.recordID,
                    let updatedAt = e.updatedAt {
                    result = DailyFocus(
                        id: id,
                        date: date,
                        text: text,
                        isDone: e.isDone,
                        recordID: recordID,
                        updatedAt: updatedAt
                    )
                }
            } catch {
                self.crashLogger.setValue("fetchDailyFocus_failed", forKey: "daily_focus")
            }
        }

        return result
    }
    
    func completeDailyFocus(for date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day)
            ?? day.addingTimeInterval(60 * 60 * 24)
        
        context.perform {
            do {
                let req: NSFetchRequest<DailyFocusEntity> = DailyFocusEntity.fetchRequest()
                req.fetchLimit = 1
                req.predicate = NSPredicate(format: "date >= %@ AND date < %@", day as NSDate, nextDay as NSDate)

                guard let e = try self.context.fetch(req).first else { return }
                e.isDone = true
                e.updatedAt = Date()
                try self.context.save()
            } catch {
                self.crashLogger.setValue("markDailyFocusDone_failed", forKey: "daily_focus")
            }
        }
    }
}
