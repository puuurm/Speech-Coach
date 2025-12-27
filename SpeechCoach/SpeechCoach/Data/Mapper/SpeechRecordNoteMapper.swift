//
//  SpeechRecordNoteMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/27/25.
//

import CoreData

enum SpeechRecordNoteMapper {
    static func upsert(
        _ note: SpeechRecord.Note?,
        into recordEntity: SpeechRecordEntity,
        in context: NSManagedObjectContext
    ) {
        guard let note else {
            if let existing = recordEntity.note {
                context.delete(existing)
                recordEntity.note = nil
            }
            return
        }
        let entity = recordEntity.note ?? SpeechRecordNoteEntity(context: context)
        apply(note, to: entity)
        entity.record = recordEntity
        recordEntity.note = entity
    }
    
    static func apply(
         _ note: SpeechRecord.Note,
         to entity: SpeechRecordNoteEntity
     ) {
         entity.intro = note.intro
         entity.strengths = note.strengths
         entity.improvements = note.improvements
         entity.nextStep = note.nextStep
     }
    
    static func toDomain(_ entity: SpeechRecordNoteEntity?) -> SpeechRecord.Note? {
        guard let entity else { return nil }
        return SpeechRecord.Note(
            intro: entity.intro ?? "",
            strengths: entity.strengths ?? "",
            improvements: entity.improvements ?? "",
            nextStep: entity.nextStep ?? ""
        )
    }

}
