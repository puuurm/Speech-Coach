//
//  SpeedBin.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/7/26.
//

import Foundation

struct SpeedBin: Codable, Hashable, Identifiable {
    let id: UUID
    let start: TimeInterval
    let end: TimeInterval
    let wordCount: Int

    init(start: TimeInterval, end: TimeInterval, wordCount: Int) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.wordCount = wordCount
    }

    var duration: TimeInterval { max(0.0001, end - start) }
    var wpm: Double { (Double(wordCount) / duration) * 60.0 }
}
