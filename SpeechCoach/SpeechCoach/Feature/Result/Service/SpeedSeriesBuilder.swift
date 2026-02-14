//
//  SpeedSeriesBuilder.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/14/25.
//

import Foundation
import SpeechCoachAnalysis

enum SpeechHighlightBuilder {

    static func makeHighlights(
        duration: TimeInterval,
        segments: [TranscriptSegment]
    ) -> [SpeechHighlight] {

        var result: [SpeechHighlight] = []

        let minHighlightLength: TimeInterval = 0.5
        let overlapTolerance: TimeInterval = 0.0

        func clamp(_ t: TimeInterval) -> TimeInterval {
            min(max(0, t), duration)
        }

        func severityRank(_ s: HighlightSeverity) -> Int {
            switch s {
            case .low: return 0
            case .medium: return 1
            case .high: return 2
            }
        }

        func overlaps(_ a: SpeechHighlight, _ b: SpeechHighlight) -> Bool {
            let aStart = a.start
            let aEnd = a.end
            let bStart = b.start
            let bEnd = b.end

            return max(aStart, bStart) < (min(aEnd, bEnd) - overlapTolerance)
        }

        func sanitized(_ h: SpeechHighlight) -> SpeechHighlight? {
            let s = clamp(h.start)
            let e = clamp(h.end)

            guard e > s else { return nil }
            guard (e - s) >= minHighlightLength else { return nil }

            return SpeechHighlight(
                title: h.title,
                detail: h.detail,
                start: s,
                end: e,
                reason: h.reason,
                category: h.category,
                severity: h.severity
            )
        }

        func upsert(_ h: SpeechHighlight) {
            guard let candidate = sanitized(h) else { return }

            for i in result.indices {
                if overlaps(result[i], candidate) {
                    if severityRank(candidate.severity) > severityRank(result[i].severity) {
                        result[i] = candidate
                    }
                    return // 겹치면 처리 끝
                }
            }

            result.append(candidate)
        }

        let gaps = PauseAnalyzer.gaps(from: segments, duration: duration)
        if let longest = gaps.max(by: { $0.duration < $1.duration }), longest.duration >= 1.2 {

            let severity: HighlightSeverity
            if longest.duration >= 2.5 {
                severity = .high
            } else if longest.duration >= 1.8 {
                severity = .medium
            } else {
                severity = .low
            }

            upsert(
                SpeechHighlight(
                    title: "가장 긴 멈춤",
                    detail: "\(String(format: "%.1f", longest.duration))초 멈춤 - 답변 정리 구간으로 보임",
                    start: longest.start,
                    end: longest.end,
                    reason: HighlightReason.longPause,
                    category: .unclearStructure,
                    severity: severity
                )
            )
        }

        let series = SpeedSeries.make(from: segments, duration: duration, binSize: 5)
        if let maxBins = series.bins.max(by: { $0.wpm < $1.wpm }), maxBins.wpm >= 170 {

            let wpm = maxBins.wpm
            let severity: HighlightSeverity
            if wpm >= 200 {
                severity = .high
            } else if wpm >= 185 {
                severity = .medium
            } else {
                severity = .low
            }

            upsert(
                SpeechHighlight(
                    title: "속도 가장 빠른 구간",
                    detail: "정보가 몰리며 말이 빨라진 구간 - 전달력 저하 가능",
                    start: maxBins.start,
                    end: maxBins.end,
                    reason: HighlightReason.fastPace,
                    category: .paceFast,
                    severity: severity
                )
            )
        }

        if let low = segments
            .compactMap({ seg -> (seg: TranscriptSegment, c: Float)? in
                guard let c = seg.confidence else { return nil }
                return (seg, c)
            })
            .min(by: { $0.c < $1.c })?
            .seg
        {
            let start = low.startTime
            let end = min(duration, low.startTime + low.duration)

            let confidence = low.confidence ?? 1.0
            let severity: HighlightSeverity
            if confidence <= 0.55 {
                severity = .high
            } else if confidence <= 0.70 {
                severity = .medium
            } else {
                severity = .low
            }

            upsert(
                SpeechHighlight(
                    title: "발음이 불명확한 구간",
                    detail: "발음 또는 환경 영향으로 말이 흐려진 구간",
                    start: start,
                    end: end,
                    reason: HighlightReason.unclearPronunciation,
                    category: .unclearPronunciation,
                    severity: severity
                )
            )
        }

        return Array(result.prefix(3))
    }
}

