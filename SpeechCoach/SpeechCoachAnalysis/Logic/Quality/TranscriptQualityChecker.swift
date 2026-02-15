//
//  TranscriptQualityChecker.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public enum TranscriptQualityChecker {

    public static func shouldHide(transcript: String, segments: [TranscriptSegment]?) -> Bool {
        let t = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return true }

        guard let segments, segments.isEmpty == false else {
            return false
        }

        let count = segments.count
        let spokenTime = segments.map(\.duration).reduce(0, +)

        let start = segments.map(\.startTime).min() ?? 0
        let end = segments.map(\.endTime).max() ?? 0
        let recognizedSpan = max(0, end - start)

        let avgSegmentDuration = spokenTime / Double(count)
        let segmentsPerSecond = recognizedSpan > 0 ? Double(count) / recognizedSpan : 0

        if count <= 8 { return true }
        if avgSegmentDuration >= 1.2 { return true }
        if segmentsPerSecond <= 0.4 { return true }

        return false
    }
}
