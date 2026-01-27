//
//  HesitationLeveler.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//

import Foundation

struct HesitationLeveler {

    struct Threshold {
        /// 분당 말 막힘 횟수 기준
        var stableMaxPerMin: Double = 2.0     // 0~2 / min
        var normalMaxPerMin: Double = 5.0     // 2~5 / min
        // 그 이상 = unstable
    }

    let threshold: Threshold
    init(threshold: Threshold = .init()) {
        self.threshold = threshold
    }

    func level(count: Int, duration: TimeInterval) -> HesitationLevel {
        guard duration > 0 else { return .normal }

        let perMin = Double(count) / (duration / 60.0)

        if perMin <= threshold.stableMaxPerMin { return .stable }
        if perMin <= threshold.normalMaxPerMin { return .normal }
        return .unstable
    }
}
