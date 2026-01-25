//
//  QualitativeRecommender.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/11/25.
//

import Foundation

enum QualitativeRecommender {
    
    static func makeFeatures(
        record: SpeechRecord,
        metrics: SpeechMetrics
    ) -> SpeechFeatures {
        SpeechFeatures(
            duration: record.duration,
            wpm: metrics.wordsPerMinute,
            fillerCount: metrics.fillerCount,
            transcriptLength: record.transcript.count
        )
    }
    
    static func recommend(
        record: SpeechRecord,
        metrics: SpeechMetrics
    ) -> QualitativeMetrics {
        let feature = makeFeatures(record: record, metrics: metrics)
        
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

extension QualitativeRecommender {
    static func makeSuggestions(
        transcript: String,
        duration: TimeInterval,
        fillerCount: Int,
        segments: [TranscriptSegment]?
    ) -> [TemplateSuggestion] {
        let speed = SpeedSeriesBuilder.make(
            duration: duration,
            transcript: transcript,
            segments: segments,
            binSeconds: 5
        )
        
        var suggestions: [TemplateSuggestion] = []
        
        if speed.variability >= 55 {
            suggestions.append(.init(
                title: "속도 안정화",
                body: "말하기 속도가 구간마다 들쭉날쭉해요. 문장 끝에서 0.5초 여유를 주고, 첫 문장을 조금만 더 천천히 시작해보세요.",
                category: .improvements
            ))
            suggestions.append(.init(
                title: "리듬 만들기",
                body: "한 문장 = 한 호흡으로 끊어가는 리듬을 먼저 만들면 속도 안정에 도움이 됩니다.",
                category: .nextStep
            ))
        } else if speed.averageWPM > 155 {
            suggestions.append(.init(
                title: "속도 조절",
                body: "전체 속도가 빠른 편이에요. 핵심 문장 앞에서는 한 박자 쉬고 강조를 넣으면 전달력이 좋아져요.",
                category: .improvements
            ))
        } else if speed.averageWPM > 0, speed.averageWPM < 95 {
            suggestions.append(.init(
                title: "속도감 올리기",
                body: "전체 속도가 느린 편이에요. 문장 사이 쉼이 길어지지 않도록 '짧게-명확하게' 말하는 연습을 해보세요.",
                category: .nextStep
            ))
        } else {
            suggestions.append(.init(
                title: "속도 유지",
                body: "전체 속도 흐름이 안정적이에요. 지금 리듬을 유지하면서 문장 끝을 더 또렷하게 마무리해보세요.",
                category: .strengths
            ))
        }
        
        if speed.maxWPM - speed.minWPM >= 80 {
            suggestions.append(.init(
                title: "급가속 구간 줄이기",
                body: "특정 구간에서 속도가 확 빨라져요. '핵심 문장'에서는 속도를 늦추고 발음을 또렷하게 가져가 보세요.",
                category: .improvements
            ))
        }
        
        if fillerCount >= 8 {
            suggestions.append(.init(
                title: "군더더기 말 줄이기",
                body: "군더더기 말(어/음)이 자주 등장해요. 생각 정리가 필요할 땐 '필러' 대신 '짧은 침묵'을 허용해보세요.",
                category: .improvements
            ))
        } else if fillerCount > 0 {
            suggestions.append(.init(
                title: "군더더기 말 관리",
                body: "군더더기 말이 조금 보이지만 전반적으로는 괜찮아요. 긴 문장 시작 전에 숨 한번 정리하면 더 좋아져요.",
                category: .strengths
            ))
        }
        
        let tokenCount = SpeedSeriesBuilder.tokenize(transcript).count
        if tokenCount < 20, duration > 20 {
            suggestions.append(.init(
                title: "녹음/발화 환경 점검",
                body: "스크립트 인식이 약했어요. 마이크 거리, 주변 소음, 발화 또렷함을 점검하면 정확도가 크게 좋아집니다.",
                category: .nextStep
            ))
        }
        
        return Array(suggestions.prefix(6))
    }
}
