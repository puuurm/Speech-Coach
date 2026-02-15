//
//  SpeedSeriesBuilder.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public enum SpeedSeriesBuilder {

    public static func make(
        duration: TimeInterval,
        transcript: String,
        segments: [TranscriptSegment]?,
        binSeconds: TimeInterval = 5
    ) -> SpeedSeries {
        let safeDuration = max(0, duration)
        guard safeDuration > 0 else {
            return SpeedSeries(binSeconds: binSeconds, bins: [])
        }

        if let segments, segments.isEmpty == false {
            return makeFromSegments(duration: safeDuration, segments: segments, binSeconds: binSeconds)
        } else {
            return makeFallback(duration: safeDuration, transcript: transcript, binSeconds: binSeconds)
        }
    }

    private static func makeFromSegments(
        duration: TimeInterval,
        segments: [TranscriptSegment],
        binSeconds: TimeInterval
    ) -> SpeedSeries {
        let bins = buildEmptyBins(duration: duration, binSeconds: binSeconds)
        guard bins.isEmpty == false else { return SpeedSeries(binSeconds: binSeconds, bins: []) }

        var counts = Array(repeating: 0, count: bins.count)

        for seg in segments {
            let words = tokenize(seg.text).count
            if words == 0 { continue }

            let idx = binIndex(for: seg.startTime, binSeconds: binSeconds)
            if idx >= 0, idx < counts.count {
                counts[idx] += words
            }
        }

        let filled: [SpeedBin] = zip(bins, counts).map { bin, c in
            SpeedBin(start: bin.start, end: bin.end, wordCount: c)
        }
        return SpeedSeries(binSeconds: binSeconds, bins: filled)
    }

    private static func makeFallback(
        duration: TimeInterval,
        transcript: String,
        binSeconds: TimeInterval
    ) -> SpeedSeries {
        let bins = buildEmptyBins(duration: duration, binSeconds: binSeconds)
        guard bins.isEmpty == false else { return SpeedSeries(binSeconds: binSeconds, bins: []) }

        let words = tokenize(transcript)
        guard words.isEmpty == false else {
            return SpeedSeries(binSeconds: binSeconds, bins: bins.map { SpeedBin(start: $0.start, end: $0.end, wordCount: 0) })
        }

        let perBin = Double(words.count) / Double(bins.count)
        let filled = bins.enumerated().map { i, b in
            let start = Int(round(Double(i) * perBin))
            let end = Int(round(Double(i + 1) * perBin))
            let c = max(0, min(words.count, end) - min(words.count, start))
            return SpeedBin(start: b.start, end: b.end, wordCount: c)
        }

        return SpeedSeries(binSeconds: binSeconds, bins: filled)
    }

    private static func buildEmptyBins(duration: TimeInterval, binSeconds: TimeInterval) -> [(start: TimeInterval, end: TimeInterval)] {
        let size = max(1.0, binSeconds)
        let count = Int(ceil(duration / size))
        guard count > 0 else { return [] }

        var result: [(TimeInterval, TimeInterval)] = []
        result.reserveCapacity(count)

        for i in 0..<count {
            let s = Double(i) * size
            let e = min(duration, Double(i + 1) * size)
            result.append((s, e))
        }
        return result
    }

    private static func binIndex(for time: TimeInterval, binSeconds: TimeInterval) -> Int {
        let size = max(1.0, binSeconds)
        return Int(floor(time / size))
    }

    static func tokenize(_ text: String) -> [String] {
        text.split { $0.isWhitespace || $0.isNewline }.map(String.init)
    }
}
