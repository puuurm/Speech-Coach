//
//  ResultAnalyzer.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public struct ResultAnalyzer: ResultAnalyzing {
    
    struct Dependencies {
        var speedSeriesBuilder: SpeedSeriesBuilding
        var speechTypeSummarizer: SpeechTypeSummarizing
        var binSeconds: TimeInterval
        
        static let live = Self (
            speedSeriesBuilder: DefaultSpeedSeriesBuilder(),
            speechTypeSummarizer: DefaultSpeechTypeSummarizer(),
            binSeconds: 5
        )
    }
    
    private let deps: Dependencies
    
    public init() {
        self.init(deps: .live)
    }
    
    init(deps: Dependencies = .live) {
        self.deps = deps
    }
    
    public func analyze(_ input: ResultAnalysisInput) -> ResultAnalysisOutput {
        let speedSeries = deps.speedSeriesBuilder.make(
            duration: input.duration,
            transcript: input.transcript,
            segments: input.segments,
            binSeconds: deps.binSeconds
        )
        
        let speechType: SpeechTypeSummary?
        if let segments = input.segments, !segments.isEmpty {
            let summary = deps.speechTypeSummarizer.summarize(
                duration: input.duration,
                wpm: input.wordsPerMinute,
                segments: segments
            )
            speechType = summary
        } else {
            speechType = nil
        }
        
        return ResultAnalysisOutput(speedSeries: speedSeries, speechType: speechType)
    }
}
