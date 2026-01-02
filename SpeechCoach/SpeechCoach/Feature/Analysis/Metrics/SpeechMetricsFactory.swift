//
//  SpeechMetricsFactory.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import Foundation

protocol SpeechMetricsMaking {
    func makeMetrics(record: SpeechRecord) -> SpeechMetrics
}

//final class SpeechMetricsFactory: SpeechMetricsMaking {
//    private let analyzer: TranscriptAnalyzer
//
//    init(analyzer: TranscriptAnalyzer = .init()) {
//        self.analyzer = analyzer
//    }
//
//    func makeMetrics(record: SpeechRecord) -> SpeechMetrics {
//        let transcript = record.transcript
//        let duration = record.duration
//
//        let wpm = analyzer.wordsPerMinute(transcript: transcript, duration: duration)
//        let fillers = analyzer.fillerCount(in: transcript)
//        let wordCount = analyzer.wordCount(in: transcript)
//
//        // 선택: window 기반 변동성(있다면)
//        let variability = analyzer.speechRateVariability(transcript: transcript, duration: duration)
//        let spikes = analyzer.speechRateSpikeCount(transcript: transcript, duration: duration)
//
//        return SpeechMetrics(
//            sessionSpeechRateWPM: wpm,
//            fillerCount: fillers,
//            duration: duration,
//            wordCount: wordCount,
//            speechRateVariability: variability,
//            spikeCount: spikes
//        )
//    }
//}
