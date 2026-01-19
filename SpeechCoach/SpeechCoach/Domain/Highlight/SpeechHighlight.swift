//
//  SpeechHighlight.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import Foundation

struct CoachDrill: Hashable, Identifiable, Codable {
    let id = UUID()
    let title: String
    let durationSec: Int
    let guide: String
    let steps: [String]
}

extension CoachDrill {
    var durationHint: String {
        let min = max(1, durationSec / 60)
        return "\(min)분"
    }
}

struct CoachDrillGuide {
    let howTo: [String]
    let successCriteria: [String]
    let commonMistakes: [String]
}

struct CoachDrillCardData {
    let drill: CoachDrill
    let guide: CoachDrillGuide
}

struct SpeechHighlight: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var start: TimeInterval
    var end: TimeInterval
    var reason: String
    
    var category: SpeechHighlightCategory
    var severity: HighlightSeverity
    
    var score: Double?
    var evidence: [String]?
}

extension SpeechHighlight {
    func coachDetail(record: SpeechRecord) -> String {
        let range = "\(formatMMSS(start))-\(formatMMSS(end))"
        let core = shortReason(record: record)
        let action = shortActionHint(record: record)
        
        if action.isEmpty { return "\(range) · \(core)" }
        return "\(range) · \(core) → \(action)"
    }
    func shortReason(record: SpeechRecord) -> String {
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.contains("가장 긴 멈춤") {
            if reason.isEmpty {
                let dur = max(0, end - start)
                return "긴 멈춤(\(String(format: "%.1f", dur))s)"
            }
            return reason
        }
        if title.contains("속도") {
            return reason.isEmpty ? "속도 변화 구간" : reason
        }
        if title.contains("신뢰도") || title.contains("인식") {
            return reason.isEmpty ? "인식 신뢰도 낮음(발음/소음 영향 가능)" : reason
        }
        return reason.isEmpty ? "주의해서 다시 볼 구간" : reason
    }
    
    func shortActionHint(record: SpeechRecord) -> String {
        if title.contains("가장 긴 멈춤") {
            return "생각-문장 연결 문구 추가"
        }
        if title.contains("속도") {
            return "핵심 문장 한 박자 쉬기"
        }
        if title.contains("신뢰도") || title.contains("인식") {
            return "원문 재확인 후 수정"
        }
        return ""
    }
}

extension SpeechHighlight {
    var timeRangeText: String {
        let s = Self.mmss(start)
        let e = Self.mmss(end)
        return "\(s)–\(e)"
    }

    func coachLineText() -> String {
        if detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "\(timeRangeText) · \(detail)"
        }
        if reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "\(timeRangeText) · \(reason)"
        }
        return "\(timeRangeText) · 이 구간을 다시 들어보면 좋아요."
    }

    static func mmss(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

func timeString(_ seconds: TimeInterval) -> String {
    let m = Int(seconds) / 60
    let s = Int(seconds) % 60
    return String(format: "%02d:%02d", m, s)
}
