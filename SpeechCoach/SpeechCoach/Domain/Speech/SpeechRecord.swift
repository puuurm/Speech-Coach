//
//  SpeechRecord.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import SpeechCoachAnalysis

struct SpeechRecord: Identifiable, Hashable, Codable {
    let id: UUID
    let createdAt: Date
    var title: String
    let duration: TimeInterval
    let summaryWPM: Int?
    let summaryFillerCount: Int?
    var metricsGeneratedAt: Date?
    let transcript: String
    var studentName: String?
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
        var checklist: String?
    }
    
    struct Insight: Hashable, Codable {
        var oneLiner: String
        var problemSummary: String
        var qualitative: QualitativeMetrics?
        var transcriptSegments: [TranscriptSegment]?
        var updatedAt: Date
    }
}

extension SpeechRecord {
    var scriptMatchSummary: ScriptMatchSummary? { nil }
    var nonverbalSummary: NonverbalSummary? { nil }
    var scriptMatchSegments: [ScriptMatchSegment]? { nil }
}

extension SpeechRecord {
    var greetingName: String {
        if let name = studentName, name.isEmpty == false {
            return "\(name)님"
        } else {
            return "학생님"
        }
    }
    
}
