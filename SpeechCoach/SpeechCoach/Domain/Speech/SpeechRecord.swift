//
//  SpeechRecord.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

struct SpeechRecord: Identifiable, Hashable, Codable {
    let id: UUID
    let createdAt: Date
    var title: String
    let duration: TimeInterval
    let wordsPerMinute: Int
    let fillerCount: Int
    let transcript: String
//    var videoURL: URL
    var fillerWords: [String: Int]
    var studentName: String
    var videoRelativePath: String?

    var note: Note?
    var insight: Insight?
    
    var highlights: [SpeechHighlight]
}

extension SpeechRecord {
    struct Note: Hashable, Codable {
        var intro: String
        var strengths: String
        var improvements: String
        var nextStep: String
    }
    
    struct Insight: Hashable, Codable {
        var oneLiner: String
        var problemSummary: String
        var qualitative: QualitativeMetrics?
        var transcriptSegments: [TranscriptSegment]?
        var updatedAt: Date
    }
}
