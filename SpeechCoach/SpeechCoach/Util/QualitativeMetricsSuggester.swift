//
//  QualitativeMetricsSuggester.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/11/25.
//

import Foundation

//struct QualitativeMetricsSuggester {
//    
//    func suggestion(
//        for record: SpeechRecord,
//        previous: SpeechRecord?
//    ) -> QualitativeMetrics {
//        
//        let delivery = suggestDelivery(record: record, previous: previous)
//        let fluency    = suggestFluency(record: record, previous: previous)
//        let naturalness = previous?.qualitative.naturalness ?? .normal
//        let eyeContact = previous?.qualitative.eyeContact ?? .normal
//        let gesture = previous?.qualitative.gesture ?? .normal
//        
//        return QualitativeMetrics(
//            delivery: delivery,
//            fluency: fluency,
//            naturalness: naturalness,
//            eyeContact: eyeContact,
//            gesture: gesture
//        )
//    }
//    
//    private func suggestDelivery(
//        record: SpeechRecord,
//        previous: SpeechRecord?
//    ) -> EmojiRating {
//        let wpm = record.wordsPerMinute
//        let fillers = record.fillerCount
//        
//        if wpm >= 70 && wpm <= 95 && fillers <= 3 {
//            return .veryGood
//        } else if wpm >= 60 && wpm <= 100 && fillers <= 5 {
//            return .good
//        } else if fillers > 10 {
//            return .bad
//        } else {
//            return .normal
//        }
//    }
//    
//    private func suggestFluency(
//        record: SpeechRecord,
//        previous: SpeechRecord?
//    ) -> EmojiRating {
//        let wpm = record.wordsPerMinute
//        
//        if wpm < 60 {
//            return .bad
//        } else if wpm <= 85 {
//            return .good
//        } else if wpm <= 100 {
//            return .normal
//        } else {
//            return .veryBad
//        }
//    }
//}
