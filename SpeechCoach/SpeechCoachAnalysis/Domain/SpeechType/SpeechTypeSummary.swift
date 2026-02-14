//
//  SpeechTypeSummary.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public struct SpeechTypeSummary: Codable, Hashable {
    public var paceType: PaceType
    public var paceStability: StabilityLevel
    public var pauseType: PauseType
    public var structureType: StructureType
    public var confidenceType: ConfidenceType
}
