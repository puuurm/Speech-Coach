//
//  SpeechRecordMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/26/25.
//

import CoreData

enum SpeechRecordMapper {

    static func toEntity(
        _ record: SpeechRecord,
        context: NSManagedObjectContext
    ) -> SpeechRecordEntity {

        let entity = SpeechRecordEntity(context: context)
        entity.id = record.id
        entity.title = record.title
        entity.createdAt = record.createdAt
        entity.duration = record.duration
        entity.videoRelativePath = record.videoRelativePath
        entity.transcript = record.transcript

        record.highlights.forEach {
            let h = SpeechHighlightMapper.toEntity($0, context: context)
            h.record = entity
        }

        return entity
    }

    static func toDomain(_ entity: SpeechRecordEntity) -> SpeechRecord {

        let highlights: [SpeechHighlight] =
            (entity.highlights as? Set<SpeechHighlightEntity>)?
                .map { SpeechHighlightMapper.toDomain($0) } ?? []

        return SpeechRecord(
            id: entity.id!,
            createdAt: entity.createdAt ?? Date(),
            title: entity.title ?? "",
            duration: entity.duration,
            wordsPerMinute: 0,
            fillerCount: highlights.count,
            transcript: entity.transcript ?? "",
            videoURL: VideoPathResolver.resolve(
                relativePath: entity.videoRelativePath
            ),
            fillerWords: [:],
            studentName: "",
            noteIntro: "",
            noteStrengths: "",
            noteImprovements: "",
            noteNextStep: "",
            qualitative: nil,
            transcriptSegments: nil,
            videoRelativePath: entity.videoRelativePath
        )
    }
}

