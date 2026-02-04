//
//  PaceClassifier.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/9/26.
//

import Foundation

struct PaceClassifier {
    var slowWPM: Int = 120
    var fastWPM: Int = 170
    var variabilityStableMax: Double = 0.18
    var spikeStableMax: Int = 2

    func paceType(from avgWPM: Int) -> PaceType {
        if avgWPM < slowWPM { return .slow }
        if avgWPM > fastWPM { return .fast }
        return .comfortable
    }

    func stability(variability: Double?, spikeCount: Int?) -> StabilityLevel {
        let v = variability ?? 0
        let s = spikeCount ?? 0

        if v > variabilityStableMax || s > spikeStableMax {
            return .unstable
        } else {
            return .stable
        }
    }

}
