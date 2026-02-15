//
//  ResultAnalysisStrategies.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

protocol SpeedSeriesBuilding {
    func make(
        duration: TimeInterval,
        transcript: String,
        segments: [TranscriptSegment]?,
        binSeconds: TimeInterval
    ) -> SpeedSeries
}

protocol SpeechTypeSummarizing {
    func summarize(
        duration: TimeInterval,
        wpm: Int,
        segments: [TranscriptSegment]
    ) -> SpeechTypeSummary
}



// MARK: - Live Implementations

struct DefaultSpeedSeriesBuilder: SpeedSeriesBuilding {
    func make(duration: TimeInterval, transcript: String, segments: [TranscriptSegment]?, binSeconds: TimeInterval) -> SpeedSeries {
        SpeedSeriesBuilder.make(duration: duration, transcript: transcript, segments: segments, binSeconds: binSeconds)
    }
}

struct DefaultSpeechTypeSummarizer: SpeechTypeSummarizing {
    func summarize(duration: TimeInterval, wpm: Int, segments: [TranscriptSegment]) -> SpeechTypeSummary {
        SpeechTypeSummarizer.summarize(duration: duration, wordsPerMinute: wpm, segments: segments)
    }
}


