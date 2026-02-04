//
//  TranscriptQualityChecker.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/26/26.
//

import Foundation

enum TranscriptQualityChecker {
    static let hideMessage =
    "주변 소음이 많아 텍스트 변환 정확도가 낮아요.\n조용한 환경에서 다시 녹음해 주세요."

    static func shouldHide(transcript: String, segments: [TranscriptSegment]?) -> Bool {
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

