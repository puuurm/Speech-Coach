//
//  SpeedBin.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public struct SpeedBin: Codable, Hashable, Identifiable {
    public let id: UUID
    public let start: TimeInterval
    public let end: TimeInterval
    public let wordCount: Int

    public init(start: TimeInterval, end: TimeInterval, wordCount: Int) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.wordCount = wordCount
    }

    public var duration: TimeInterval { max(0.0001, end - start) }
    public var wpm: Double { (Double(wordCount) / duration) * 60.0 }
}
