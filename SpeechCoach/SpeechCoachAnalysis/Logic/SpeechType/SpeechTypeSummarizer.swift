//
//  SpeechTypeSummarizer.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public enum SpeechTypeSummarizer {
    public static func summarize(
        duration: TimeInterval,
        wordsPerMinute: Int,
        segments: [TranscriptSegment]
    ) -> SpeechTypeSummary {
        let paceType = inferPaceType(wpm: wordsPerMinute)
        let stability = inferPaceStability(duration: duration, segments: segments)
        let pauseType = inferPauseType(duration: duration, segments: segments)
        let structureType = inferStructureType(segments: segments)
        let confidenceType = inferConfidenceType(segments: segments)
        
        return SpeechTypeSummary(
            paceType: paceType,
            paceStability: stability,
            pauseType: pauseType,
            structureType: structureType,
            confidenceType: confidenceType
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
}
