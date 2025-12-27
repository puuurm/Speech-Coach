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
    
    private let storageKey = "SpeechRecordStore.recentRecords"
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }
    
    private let maxRecentCount: Int = 20
    
    init(container: NSPersistentContainer = .init(name: "SpeechCoachDataModel")) {
        self.container = container
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        reload()
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
