//
//  QualitativeRecommender.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/11/25.
//

import Foundation

enum QualitativeRecommender {
    
    static func makeFeatures(from record: SpeechRecord) -> SpeechFeatures {
        SpeechFeatures(
            duration: record.duration,
            wpm: record.wordsPerMinute,
            fillerCount: record.fillerCount,
            transcriptLength: record.transcript.count
        )
    }
    
    static func recommend(for record: SpeechRecord) -> QualitativeMetrics {
        let feature = makeFeatures(from: record)
        
        let delivery = recommendDelivery(from: feature)
        let clarity = recommendClarity(from: feature)
        let confidence = recommendConfidence(from: feature)
        let structure = recommendStructure(from: feature)

        return QualitativeMetrics(
            delivery: delivery,
            clarity: clarity,
            confidence: confidence,
            structure: structure
        )
    }
    
    private static func recommendDelivery(from feature: SpeechFeatures) -> EmojiRating {
        switch feature.wpm {
        case ..<70:   return .low
        case 70..<90: return .neutral
        case 90..<140: return .high
        case 140..<170: return .neutral
        default: return .low
        }
    }
    
    private static func recommendClarity(from feature: SpeechFeatures) -> EmojiRating {
        switch feature.fillerRatio {
        case 0..<0.005:   return .veryHigh
        case 0.005..<0.015: return .high
        case 0.015..<0.03: return .neutral
        case 0.03..<0.05: return .low
        default:         return .veryLow
        }
    }
    
    private static func recommendConfidence(from feature: SpeechFeatures) -> EmojiRating {
        let base: EmojiRating
        switch feature.wpm {
        case 0..<60:    base = .low
        case 60..<90:   base = .neutral
        case 90..<140:  base = .high
        case 140..<180: base = .neutral
        default:        base = .low
        }
        
        if feature.fillerPerMinute > 12 {
            return .veryLow
        } else if feature.fillerPerMinute > 8 {
            return .low
        }
        return base
    }
    
    private static func recommendStructure(from feature: SpeechFeatures) -> EmojiRating {
        switch feature.transcriptLength {
        case 0..<80:    return .low
        case 80..<200:  return .neutral
        case 200..<600: return .high
        default:        return .veryHigh
        }
    }
}
