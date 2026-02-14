//
//  TranscriptResult.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/13/25.
//

import Foundation
import SpeechCoachAnalysis

struct TranscriptResult: Codable, Hashable {
    let rawText: String
    let cleanedText: String
    let segments: [TranscriptSegment]
}
