//
//  SpeechAnalysisLevels.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import Foundation
import SpeechCoachAnalysis

public extension PaceType {
    var displayName: String {
        switch self {
        case .slow: return "느림"
        case .comfortable: return "적정"
        case .fast: return "빠름"
        }
    }
}

public extension StabilityLevel {
    var displayName: String {
        switch self {
        case .stable: return "페이스 안정적"
        case .mixed: return "페이스 약간 흔들림"
        case .unstable: return "페이스 흔들림"
        }
    }
}

public extension PauseType {
    var displayName: String {
        switch self {
        case .smooth: return "느림"
        case .thinkingPause: return "적정"
        case .choppy: return "빠름"
        }
    }
}

public extension StructureType {
    var displayName: String {
        switch self {
        case .clear: return "구조 명확"
        case .partial: return "부분적으로 구조 있음"
        case .unclear: return "구조 흐림"
        }
    }
}

public extension ConfidenceType {
    var displayName: String {
        switch self {
        case .confident: return "자신감 있음"
        case .neutral: return "보통"
        case .hesitant: return "조심/망설임"
        }
    }
}

