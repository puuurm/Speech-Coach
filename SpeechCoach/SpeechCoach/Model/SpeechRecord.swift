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
    let videoURL: URL
    let fillerWords: [String: Int]
    
    var studentName: String
    var noteIntro: String
    var noteStrengths: String
    var noteImprovements: String
    var noteNextStep: String
    
    var qualitative: QualitativeMetrics = .empty
}

