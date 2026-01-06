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
        nextStep: String
    ) {
        context.perform {
            do {
                guard let entity = try self.fetchRecordEntity(id: id) else { return }
                let noteEntity = entity.note ?? SpeechRecordNoteEntity(context: self.context)
                noteEntity.record = entity
                entity.note = noteEntity
                
                SpeechRecordNoteMapper.apply(
                    SpeechRecord.Note(
                        intro: intro,
                        strengths: strenghts,
                        improvements: improvements,
                        nextStep: nextStep
                    ),
                    to: noteEntity
                )
                try self.saveContext()
                self.reload()
                print("Updated notes for record:", id)
            } catch {
                assertionFailure("❌ updateNotes failed: \(error)")
            }
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

                try self.saveContext()
                self.reload()
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
    
    private func fetchMetricsEntity(recordID: UUID) throws -> SpeechMetricsEntity? {
        let request = SpeechMetricsEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "recordID == %@", recordID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "generatedAt", ascending: false)]
        return try context.fetch(request).first
    }
    
    func updateVideoRelativePath(recordID: UUID, relativePath: String) {
        context.perform {
            do {
                guard let entity = try self.fetchRecordEntity(id: recordID) else {
                    assertionFailure("❌ Record not found: \(recordID)")
                    return
                }

                // ✅ domain-only 수정 금지. 엔티티에 저장.
                entity.videoRelativePath = relativePath

                // videoURL은 Core Data에 저장하지 않는다면(일반적), domain에서 resolve
                // 즉, mapper의 toDomain에서 relativePath -> resolved URL 처리하도록 통일 추천

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
