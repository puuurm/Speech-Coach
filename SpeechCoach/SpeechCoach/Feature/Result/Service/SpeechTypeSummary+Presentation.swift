//
//  SpeechTypeSummary.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/15/25.
//

import Foundation
import SpeechCoachAnalysis

extension SpeechTypeSummary {
    
    var oneLiner: String {
        SpeechTypeOneLinerBuilder.make(from: self)
    }

    func clipboardText(for record: SpeechRecord) -> String {
        var lines: [String] = []

        lines.append("말하기 타입 요약")
        lines.append(oneLiner)

        lines.append("· 속도: \(paceType.label) / 안정: \(paceStability.label)")
        lines.append("· 쉬는 습관: \(pauseType.label)")
        lines.append("· 구조: \(structureType.label)")
        lines.append("· 자신감: \(confidenceType.label)")

        if record.highlights.isEmpty == false {
            lines.append("")
            lines.append("체크할 구간")
            for h in record.highlights.prefix(3) {
                lines.append("· \(h.coachDetail(record: record))")
            }
        }

        return lines.joined(separator: "\n")
    }

    func memoSnippet(for record: SpeechRecord) -> String {
        var parts: [String] = []
        parts.append("【말하기 타입 요약】 \(oneLiner)")
        if let h = record.highlights.first {
            parts.append("체크 구간: \(h.coachDetail(record: record))")
        }
        return parts.joined(separator: "\n")
    }
    
    func displayReasons() -> [String] {
        var result: [String] = []
        switch paceType {
        case .slow:
            result.append("평균 말하기 속도가 느린 편이에요")
        case .comfortable:
            result.append("평균 말하기 속도가 적정 범위에 있어요")
        case .fast:
            result.append("평균 말하기 속도가 빠른 편이에요")
        }
        
        switch paceStability {
        case .stable:
            result.append("구간별 속도 변화가 크지 않아요")
        case .unstable:
            result.append("구간별 속도 변화가 느껴질 수 있어요")
        default: break
        }
        return Array(result.prefix(2))
    }
    
    func clipboardText() -> String {
        var lines = [oneLiner]
        let reasons = displayReasons()
        if reasons.isEmpty == false {
            lines.append("")
            lines.append("왜 이렇게 판단했나요?")
            lines.append(contentsOf: reasons.map { "• \($0)" })
        }
        return lines.joined(separator: "\n")
    }
}


