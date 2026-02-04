//
//  SpeechMetrics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import Foundation

struct SpeechMetrics: Hashable, Codable {
    let recordID: UUID
    let generatedAt: Date
    let wordsPerMinute: Int
    let fillerCount: Int
    let fillerWords: [String: Int]
    let paceVariability: Double?
    let spikeCount: Int?
}
