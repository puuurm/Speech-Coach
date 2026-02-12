//
//  ResultAnalysisInput.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/7/26.
//

import Foundation

struct ResultAnalysisInput {
    let duration: TimeInterval
    let transcript: String
    let segments: [TranscriptSegment]?
    let metrics: SpeechMetrics
}
