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
    
    init(context: NSManagedObjectContext) {
        self.context = context
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
                assertionFailure("❌ upsertBundle failed: \(error)")
            }
        }
    }
    
    func saveCoachingMemo(recordID: UUID, memo: String) throws {
        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let record = try fetchOrCreateRecordEntity(id: recordID)
        let note = try fetchOrCreateNote(for: record)
        note.coachingMemo = trimmed.isEmpty ? nil : trimmed
        note.updatedAt = Date()
        try context.save()
        objectWillChange.send()
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
        
        try await context.perform {
            guard context.hasChanges else { return }
            try context.save()
        }
        self.reload()
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
}
