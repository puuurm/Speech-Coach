//
//  ResultAnalysisInput.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public struct ResultAnalysisInput {
    public let duration: TimeInterval
    public let transcript: String
    public let segments: [TranscriptSegment]?
    public let wordsPerMinute: Int
    
    public init(
        duration: TimeInterval,
        transcript: String,
        segments: [TranscriptSegment]?,
        wordsPerMinute: Int
    ) {
        self.duration = duration
        self.transcript = transcript
        self.segments = segments
        self.wordsPerMinute = wordsPerMinute
    }
}
