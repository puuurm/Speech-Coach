//
//  SpeechTypeEnums.swift
//  SpeechCoachAnalysis
//
//  Created by Heejung Yang on 2/14/26.
//

import Foundation

public enum PaceType: String, Codable, CaseIterable {
    case slow = "느림"
    case comfortable = "적정"
    case fast = "빠름"
}

public enum StabilityLevel: String, Codable, CaseIterable {
    case stable = "안정"
    case mixed = "변동"
    case unstable = "불안정"
}

public enum PauseType: String, Codable, CaseIterable {
    case smooth = "느림"
    case thinkingPause = "적정"
    case choppy = "빠름"
}

public enum StructureType: String, Codable, CaseIterable {
    case clear = "구조 명확"
    case partial = "부분적으로 구조 있음"
    case unclear = "구조 흐림"
}

public enum ConfidenceType: String, Codable, CaseIterable {
    case confident = "자신감 있음"
    case neutral = "보통"
    case hesitant = "조심/망설임"
}
