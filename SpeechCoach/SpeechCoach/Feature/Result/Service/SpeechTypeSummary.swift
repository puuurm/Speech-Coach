//
//  SpeechTypeSummary.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/15/25.
//

import Foundation

struct SpeechTypeSummary: Codable, Hashable {
    var paceType: PaceType
    var paceStability: StabilityLevel
    var pauseType: PauseType
    var structureType: StructureType
    var confidenceType: ConfidenceType
    var oneLiner: String
}

extension SpeechTypeSummary {

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
}

extension SpeechTypeSummary {
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
        if reasons.isEmpty {
            lines.append("")
            lines.append("왜 이렇게 판단했나요?")
            lines.append(contentsOf: reasons.map { "• \($0)" })
        }
        return lines.joined(separator: "\n")
    }
}

enum SpeechTypeSummarizer {
    static func summarize(
        duration: TimeInterval,
        wordsPerMinute: Int,
        segments: [TranscriptSegment]
    ) -> SpeechTypeSummary {
        let paceType = inferPaceType(wpm: wordsPerMinute)
        let stability = inferPaceStability(duration: duration, segments: segments)
        let pauseType = inferPauseType(duration: duration, segments: segments)
        let structureType = inferStructureType(segments: segments)
        let confidenceType = inferConfidenceType(segments: segments)
                
        let oneLiner = makeOneLiner(
            paceType: paceType,
            stability: stability,
            pauseType: pauseType,
            structure: structureType,
            confidence: confidenceType
        )
        
        return SpeechTypeSummary(
            paceType: paceType,
            paceStability: stability,
            pauseType: pauseType,
            structureType: structureType,
            confidenceType: confidenceType,
            oneLiner: oneLiner
        )
    }
    
    static func inferPaceType(wpm: Int) -> PaceType {
        switch wpm {
        case 0..<110: return .slow
        case 110...160: return .comfortable
        default: return .fast
        }
    }
    
    static func inferPaceStability(duration: TimeInterval, segments: [TranscriptSegment]) -> StabilityLevel {
        let series = SpeedSeries.make(from: segments, duration: duration, binSize: 5)
        
        guard series.bins.count >= 3 else { return .mixed }
        
        let values = series.bins.map(\.wpm)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let sd = sqrt(variance)
        
        if sd < 12 { return .stable }
        if sd < 25 { return .mixed }
        return .unstable
    }
    
    static func inferPauseType(duration: TimeInterval, segments: [TranscriptSegment]) -> PauseType {
        let gaps = PauseAnalyzer.gaps(from: segments, duration: duration)
        guard duration > 0 else { return .smooth }

        let longPauses = gaps.filter { $0.duration >= 1.0 }
        let veryLong = gaps.filter { $0.duration >= 2.0 }

        let minutes = max(duration / 60.0, 0.5)
        let longPerMin = Double(longPauses.count) / minutes
        let veryLongPerMin = Double(veryLong.count) / minutes

        if veryLongPerMin >= 0.6 { return .thinkingPause }
        if longPerMin >= 1.5 { return .choppy }
        return .smooth
    }
    
    static func inferStructureType(segments: [TranscriptSegment]) -> StructureType {
        let text = segments.map(\.text).joined(separator: " ")

        let introSignals = ["먼저", "첫째", "우선", "오늘", "주제", "결론부터"]
        let wrapSignals = ["정리", "마무리", "결론", "요약", "결과적으로", "즉"]

        let hasIntro = introSignals.contains { text.contains($0) }
        let hasWrap = wrapSignals.contains { text.contains($0) }

        switch (hasIntro, hasWrap) {
        case (true, true): return .clear
        case (true, false), (false, true): return .partial
        default: return .unclear
        }
    }

    static func inferConfidenceType(segments: [TranscriptSegment]) -> ConfidenceType {
        let confidences = segments.compactMap(\.confidence)
        guard segments.isEmpty == false, confidences.isEmpty == false else { return .neutral }
        let avg = confidences.reduce(0, +) / Float(confidences.count)
        
        if avg >= 0.70 { return .confident }
        if avg >= 0.55 { return .neutral }
        return .hesitant
    }
    
    static func makeOneLiner(
        paceType: PaceType,
        stability: StabilityLevel,
        pauseType: PauseType,
        structure: StructureType,
        confidence: ConfidenceType
    ) -> String {
        return "\(paceType.rawValue) 속도 / \(stability.rawValue) / \(pauseType.rawValue) / \(structure.rawValue) / \(confidence.rawValue)"
    }
    
}

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
