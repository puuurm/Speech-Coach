//
//  SpeechHighlightMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/26/25.
//

import CoreData

enum SpeechHighlightMapper {

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
        entity.severity = Int64(highlight.severity.rawValue)

        return entity
    }

    static func toDomain(_ entity: SpeechHighlightEntity) -> SpeechHighlight {
        SpeechHighlight(
            id: entity.id!,
            title: entity.title ?? "",
            detail: entity.detail ?? "",
            start: entity.start,
            end: entity.end,
            reason: "",

            category: CoachIssueCategory(
                rawValue: entity.category ?? ""
            ) ?? .paceSlow,

            severity: HighlightSeverity(
                rawValue: Int(entity.severity)
            ) ?? .medium
        )
    }

}
