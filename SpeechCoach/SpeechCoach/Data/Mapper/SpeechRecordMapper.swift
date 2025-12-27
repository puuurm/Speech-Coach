//
//  SpeechRecordMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/26/25.
//

import CoreData

enum SpeechRecordMapper {
    static func upsert(_ record: SpeechRecord, in context: NSManagedObjectContext) -> SpeechRecordEntity {
        let entity = fetch(by: record.id, in: context) ?? SpeechRecordEntity(context: context)
        apply(record, to: entity, context: context)
        return entity
    }
    
    static func apply(
        _ record: SpeechRecord,
        to entity: SpeechRecordEntity,
        context: NSManagedObjectContext
    ) {
        entity.id = record.id
        entity.createdAt = record.createdAt
        entity.title = record.title
        entity.duration = record.duration
        entity.wordsPerMinute = Int32(record.wordsPerMinute)
        entity.fillerCount = Int32(record.fillerCount)
        entity.transcript = record.transcript
        entity.studentName = record.studentName
        entity.videoRelativePath = record.videoRelativePath
        
        entity.fillerWordsData = CodableStore.encode(record.fillerWords)
        
        SpeechRecordNoteMapper.upsert(record.note, into: entity, in: context)
        SpeechRecordInsightMapper.upsert(record.insight, into: entity, in: context)
        
        replaceHighlights(record.highlights, into: entity, in: context)
    }
    
    static func fetch(by id: UUID, in context: NSManagedObjectContext) -> SpeechRecordEntity? {
        let request = SpeechRecordEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return (try? context.fetch(request))?.first
    }
    
    static func replaceHighlights(
        _ highlights: [SpeechHighlight],
        into recordEntity: SpeechRecordEntity,
        in context: NSManagedObjectContext
    ) {
        if let existing = recordEntity.highlights as? Set<SpeechHighlightEntity> {
            for exist in existing {
                context.delete(exist)
            }
        }
        recordEntity.highlights = nil
        
        for highlight in highlights {
            let entity = SpeechHighlightEntity(context: context)
            SpeechHighlightMapper.toEntity(highlight, context: context)
            entity.record = recordEntity
        }
    }

    static func toDomain(_ entity: SpeechRecordEntity) -> SpeechRecord {
        let id = entity.id ?? UUID()
        let createdAt = entity.createdAt ?? Date()
        
        let fillerWords: [String: Int] = CodableStore.decode([String: Int].self, from: entity.fillerWordsData) ?? [:]
        
        return SpeechRecord(
            id: id,
            createdAt: createdAt,
            title: entity.title ?? "",
            duration: entity.duration,
            wordsPerMinute: Int(entity.wordsPerMinute),
            fillerCount: Int(entity.fillerCount),
            transcript: entity.transcript ?? "",
            fillerWords: fillerWords,
            studentName: entity.studentName ?? "",
            videoRelativePath: entity.videoRelativePath,
            note: SpeechRecordNoteMapper.toDomain(entity.note),
            insight: SpeechRecordInsightMapper.toDomain(entity.insight),
            highlights: SpeechHighlightMapper.toDomain(entity.highlights as? Set<SpeechHighlightEntity>)
        )
    }
}

