//
//  DailyFocus.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/4/26.
//

import Foundation

struct DailyFocus: Identifiable, Equatable {
    let id: UUID
    let date: Date               // startOfDay
    let text: String
    let isDone: Bool
    let recordID: UUID?
    let updatedAt: Date
}

enum DailyFocusBuilder {

    static func makeAutoFocusText(
        record: SpeechRecord,
        metrics: SpeechMetrics
    ) -> String? {

        let wpm = Int(metrics.wordsPerMinute)
        guard wpm > 0 else { return nil }

        switch wpm {
        case ..<105:
            return clip("오늘은 문장 끝을 또렷하게 마무리하고, 핵심 문장을 한 번 더 힘줘서 말해보기 (\(wpm)wpm)", maxLength: 52)

        case 165...:
            return clip("오늘은 핵심 문장마다 0.5초 멈추고, 호흡을 정리한 뒤 이어 말해보기 (\(wpm)wpm)", maxLength: 52)

        default:
            return nil
        }
    }

    static func makeManualFocusText(
        improvements: String,
        checklist: String,
        nextSteps: String
    ) -> String? {

        let raw = [improvements, checklist, nextSteps]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        guard let raw else { return nil }

        let line = raw
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })?
            .replacingOccurrences(of: "•", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let line, !line.isEmpty else { return nil }
        return clip(line, maxLength: 52)
    }

    static func makeTodayFocusText(
        record: SpeechRecord?,
        metrics: SpeechMetrics?,
        improvements: String,
        checklist: String,
        nextSteps: String
    ) -> String? {

        if let record, let metrics {
            if let auto = makeAutoFocusText(record: record, metrics: metrics) {
                return auto
            }
        }

        return makeManualFocusText(
            improvements: improvements,
            checklist: checklist,
            nextSteps: nextSteps
        )
    }

    private static func clip(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        let end = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<end]).trimmingCharacters(in: .whitespaces) + "…"
    }
}
