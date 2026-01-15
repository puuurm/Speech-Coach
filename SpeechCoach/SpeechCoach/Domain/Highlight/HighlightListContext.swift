//
//  HighlightRowStyle.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/15/26.
//

import Foundation

enum HighlightListContext {
    case feedbackAnalysis
    case videoReview
    case homeAnalysis
}

func formatMMSS(_ sec: TimeInterval) -> String {
    let s = max(0, Int(sec.rounded(.down)))
    let m = s / 60
    let r = s % 60
    return String(format: "%02d:%02d", m, r)
}

func timeRangeText(_ h: SpeechHighlight) -> String {
    "\(formatMMSS(h.start))–\(formatMMSS(h.end))"
}
