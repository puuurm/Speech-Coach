//
//  SpeechTypeSummaryViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel (SpeechMetrics -> SpeechTypeSummary UI)

@MainActor
final class SpeechTypeSummaryViewModel: ObservableObject {
    @Published private(set) var speechType: SpeechTypeSummary?
    
    private let paceClassifier = PaceClassifier()
    
    func load(
        duration: TimeInterval,
        wordsPerMinute: Int,
        segments: [TranscriptSegment]
    ) {
        var summary = SpeechTypeSummarizer.summarize(
            duration: duration,
            wordsPerMinute: wordsPerMinute,
            segments: segments
        )
        summary.oneLiner = SpeechTypeOneLinerBuilder.make(from: summary)
        self.speechType = summary
    }
    
    func reset() {
        speechType = nil
    }
}
