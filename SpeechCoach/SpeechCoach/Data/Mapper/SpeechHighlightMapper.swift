//
//  SpeechHighlightMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/26/25.
//

import CoreData

enum SpeechHighlightMapper {
    static func replaceAll(
        _ highlights: [SpeechHighlight],
        into recordEntity: SpeechRecordEntity,
        in context: NSManagedObjectContext
    ) {
        if let existing = recordEntity.highlights as? Set<SpeechHighlightEntity> {
            for exist in existing {
                context.delete(exist)
            }
        }
        
        for highlight in highlights {
            let entity = SpeechHighlightEntity(context: context)
            apply(highlight, to: entity)
            entity.record = recordEntity
        }
    }
    
    static func apply(
        _ highlight: SpeechHighlight,
        to entity: SpeechHighlightEntity
    ) {
        entity.id = highlight.id
        entity.title = highlight.title
        entity.detail = highlight.detail
        entity.start = highlight.start
        entity.end = highlight.end
        entity.reason = highlight.reason
        entity.category = highlight.category.rawValue
        entity.severity = Int16(highlight.severity.rawValue)
    }

    static func toEntity(
        _ highlight: SpeechHighlight,
        context: NSManagedObjectContext
    ) -> SpeechHighlightEntity {

        let entity = SpeechHighlightEntity(context: context)
        entity.id = highlight.id
        entity.title = highlight.title
        entity.detail = highlight.detail
        entity.start = highlight.start
        entity.end = highlight.end
        entity.category = highlight.category.rawValue
        entity.severity = Int16(highlight.severity.rawValue)

        return entity
    }

    static func toDomain(_ entities: Set<SpeechHighlightEntity>?) -> [SpeechHighlight] {
        let list = (entities ?? []).sorted { $0.start < $1.start }
        return list.compactMap { entity -> SpeechHighlight? in
            guard let id = entity.id else { return nil }
            return SpeechHighlight(
                id: id,
                title: entity.title ?? "",
                detail: entity.detail ?? "",
                start: entity.start,
                end: entity.end,
                reason: entity.reason ?? "",
                category: CoachIssueCategory(rawValue: entity.category ?? "") ?? .longPause,
                severity: HighlightSeverity(rawValue: Int(entity.severity)) ?? .medium
            )
        }
    }
}
