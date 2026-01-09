//
//  SpeechTypeOneLinerBuilder.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/9/26.
//

import Foundation

enum SpeechTypeOneLinerBuilder {
    static func make(from summary: SpeechTypeSummary) -> String {
        let base = baseSentence(
            paceType: summary.paceType,
            stability: summary.paceStability
        )
        
        let candidates = supplementaryPhrases(
            pauseType: summary.pauseType,
            structureType: summary.structureType,
            confidenceType: summary.confidenceType
        )
        
        if let supplement = candidates.first {
            return "\(base) \(supplement)"
        } else {
            return base
        }
    }
    
    private static func baseSentence(
        paceType: PaceType,
        stability: StabilityLevel
    ) -> String {
        let pace: String = {
            switch paceType {
            case .slow:
                return "전반적으로 천천히 말하고 있어요."
            case .comfortable:
                return "속도는 전반적으로 적절해요."
            case .fast:
                return "전반적으로 빠르게 말하고 있어요."
            }
        }()
        
        let stabilityPhrase: String = {
            switch stability {
            case .stable:
                return "속도 변화는 크지 않아요."
            case .mixed:
                return "일부 구간에서 리듬이 달라질 수 있어요."
            case .unstable:
                return "구간별 속도 차이가 느껴져요."
            }
        }()
        
        return "\(pace) \(stabilityPhrase)"
    }
    
    private static func supplementaryPhrases(
        pauseType: PauseType,
        structureType: StructureType,
        confidenceType: ConfidenceType
    ) -> [String] {

        var results: [String] = []

        switch pauseType {
        case .thinkingPause:
            results.append("중간중간 생각하며 쉬는 구간이 보여요.")
        case .choppy:
            results.append("문장 사이 호흡이 자주 끊기는 편이에요.")
        case .smooth:
            break
        }

        switch structureType {
        case .unclear:
            results.append("전체 흐름이 조금 분산되어 들릴 수 있어요.")
        case .partial:
            results.append("구조는 일부 구간에서만 드러나요.")
        case .clear:
            break
        }

        switch confidenceType {
        case .hesitant:
            results.append("말끝에서 확신이 약해질 수 있어요.")
        case .neutral:
            break
        case .confident:
            results.append("전반적으로 자신감 있는 톤이에요.")
        }

        return results
    }

}
