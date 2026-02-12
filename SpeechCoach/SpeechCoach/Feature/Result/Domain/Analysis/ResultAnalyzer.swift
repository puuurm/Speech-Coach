//
//  ResultAnalyzer.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/7/26.
//

import Foundation

struct ResultAnalyzer: ResultAnalyzing {
    
    struct Dependencies {
        var speedSeriesBuilder: SpeedSeriesBuilding
        var speechTypeSummarizer: SpeechTypeSummarizing
        var oneLinerBuilder: SpeechTypeOneLinerBuilding
        var binSeconds: TimeInterval
        
        static let live = Self (
            speedSeriesBuilder: DefaultSpeedSeriesBuilder(),
            speechTypeSummarizer: DefaultSpeechTypeSummarizer(),
            oneLinerBuilder: DefaultSpeechTypeOneLinerBuilder(),
            binSeconds: 5
        )
    }
    
    private let deps: Dependencies
    
    init(deps: Dependencies = .live) {
        self.deps = deps
    }
    
    func analyze(_ input: ResultAnalysisInput) -> ResultAnalysisOutput {
        let speedSeries = SpeedSeriesBuilder.make(
            duration: input.duration,
            transcript: input.transcript,
            segments: input.segments,
            binSeconds: deps.binSeconds
        )
        
        let speechType: SpeechTypeSummary?
        if let segments = input.segments, !segments.isEmpty {
            var summary = SpeechTypeSummarizer.summarize(
                duration: input.duration,
                wordsPerMinute: input.metrics.wordsPerMinute,
                segments: segments
            )
            summary.oneLiner = SpeechTypeOneLinerBuilder.make(from: summary)
            speechType = summary
        } else {
            speechType = nil
        }
        
        return ResultAnalysisOutput(speedSeries: speedSeries, speechType: speechType)
    }
}
