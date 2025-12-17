//
//  SpeechHighlight.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import Foundation

struct SpeechHighlight: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var start: TimeInterval
    var end: TimeInterval
    var reason: String
}

extension SpeechHighlight {
    func coachDetail(record: SpeechRecord) -> String {
        let range = "\(start.toClock())-\(end.toClock())"
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

// 네 프로젝트에 이미 SpeechHighlight가 있다고 가정
// struct SpeechHighlight: Identifiable, Codable, Hashable {
//   var id: UUID = UUID()
//   var title: String
//   var detail: String
//   var start: TimeInterval
//   var end: TimeInterval
//   var reason: String
// }

extension SpeechHighlight {

    var timeRangeText: String {
        let s = Self.mmss(start)
        let e = Self.mmss(end)
        return "\(s)–\(e)"
    }

    /// ResultScreen에 보여줄 "짧은 강사용 문장"
    func coachDetail(recordDuration: TimeInterval) -> String {
        // detail을 비워둔 상태라면, 기본은 time + reason으로 구성
        if detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "\(timeRangeText) · \(detail)"
        }
        if reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "\(timeRangeText) · \(reason)"
        }
        // 최후 fallback
        return "\(timeRangeText) · 이 구간을 다시 들어보면 좋아요."
    }

    static func mmss(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
