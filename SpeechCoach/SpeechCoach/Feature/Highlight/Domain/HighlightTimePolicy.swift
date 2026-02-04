//
//  HighlightTimePolicy.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/16/26.
//

import Foundation

func normalizedSecond(_ t: TimeInterval) -> TimeInterval {
    TimeInterval(max(0, Int(t.rounded())))
}

func formatMMSS(_ t: TimeInterval) -> String {
    let s = Int(normalizedSecond(t))
    let m = s / 60
    let r = s % 60
    return "\(m):\(String(format: "%02d", r))"
}

func timeRangeText(_ highlight: SpeechHighlight) -> String {
    "\(formatMMSS(highlight.start))–\(formatMMSS(highlight.end))"
}
