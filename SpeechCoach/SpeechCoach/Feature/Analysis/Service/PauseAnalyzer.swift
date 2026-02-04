//
//  PauseAnalyzer.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/15/25.
//

import Foundation

enum PauseAnalyzer {
    struct Gap: Hashable {
        var start: TimeInterval
        var end: TimeInterval
        var duration: TimeInterval { max(0, end - start) }
    }
    
    static func gaps(from segments: [TranscriptSegment], duration: TimeInterval) -> [Gap] {
        guard duration > 0 else { return [] }
        let sorted = segments.sorted(by: { $0.startTime < $1.startTime })
        guard sorted.count >= 2 else { return [] }
        
        var gaps: [Gap] = []
        for i in 0..<(sorted.count - 1) {
            let currentEnd = sorted[i].startTime + sorted[i].duration
            let nextStart = sorted[i + 1].startTime
            if currentEnd < nextStart {
                gaps.append(Gap(start: currentEnd, end: min(duration, nextStart)) )
            }
        }
        return gaps
    }
}
