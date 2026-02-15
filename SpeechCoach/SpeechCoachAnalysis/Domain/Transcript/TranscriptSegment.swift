//
//  TranscriptSegment.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public struct TranscriptSegment: Codable, Hashable {
    public let text: String
    public let startTime: TimeInterval
    public let duration: TimeInterval  
    public let confidence: Float?

    public var endTime: TimeInterval { startTime + duration }

    public init(
        text: String,
        startTime: TimeInterval,
        duration: TimeInterval,
        confidence: Float? = nil
    ) {
        self.text = text
        self.startTime = startTime
        self.duration = duration
        self.confidence = confidence
    }
}
