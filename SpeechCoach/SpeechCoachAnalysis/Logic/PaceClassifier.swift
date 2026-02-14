//
//  PaceClassifier.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public struct PaceClassifier {
    public var slowWPM: Int = 120
    public var fastWPM: Int = 170
    public var variabilityStableMax: Double = 0.18
    public var spikeStableMax: Int = 2
    
    public init() {
        self.init(slowWPM: 120, fastWPM: 170, variabilityStableMax: 0.18, spikeStableMax: 2)
    }
    
    init(slowWPM: Int, fastWPM: Int, variabilityStableMax: Double, spikeStableMax: Int) {
        self.slowWPM = slowWPM
        self.fastWPM = fastWPM
        self.variabilityStableMax = variabilityStableMax
        self.spikeStableMax = spikeStableMax
    }

    public func paceType(from avgWPM: Int) -> PaceType {
        if avgWPM < slowWPM { return .slow }
        if avgWPM > fastWPM { return .fast }
        return .comfortable
    }

    public func stability(variability: Double?, spikeCount: Int?) -> StabilityLevel {
        let v = variability ?? 0
        let s = spikeCount ?? 0

        if v > variabilityStableMax || s > spikeStableMax {
            return .unstable
        } else {
            return .stable
        }
    }

}
