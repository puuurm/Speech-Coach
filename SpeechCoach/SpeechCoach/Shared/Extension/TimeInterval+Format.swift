//
//  TimeInterval+Format.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import Foundation

extension TimeInterval {
    func toClock() -> String {
        let total = max(0, Int(self.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
