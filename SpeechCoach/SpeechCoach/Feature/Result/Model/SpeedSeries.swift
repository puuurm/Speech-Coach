//
//  SpeedSeries.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/14/25.
//

import Foundation

struct SpeedSeries: Codable, Hashable {
    let binSeconds: TimeInterval
    let bins: [SpeedBin]

    var averageWPM: Double {
        guard bins.isEmpty == false else { return 0 }
        let totalWords = bins.reduce(0) { $0 + $1.wordCount }
        let totalSeconds = bins.reduce(0.0) { $0 + ($1.end - $1.start) }
        guard totalSeconds > 0 else { return 0 }
        return (Double(totalWords) / totalSeconds) * 60.0
    }

    var variability: Double {
        let values = bins.map { $0.wpm }
        guard values.count >= 2 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let v = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1)
        return sqrt(v)
    }

    var maxWPM: Double { bins.map(\.wpm).max() ?? 0 }
    var minWPM: Double { bins.map(\.wpm).min() ?? 0 }
}
