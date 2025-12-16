//
//  SpeechTypeSummary.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/15/25.
//

import Foundation

struct SpeechTypeSummary: Codable, Hashable {
    var paceType: PaceType
    var paceStability: StabilityLevel
    var pauseType: PauseType
    var structureType: StructureType
    var confidenceType: ConfidenceType
    
    var oneLiner: String
    
    var highlights: [SpeechHighlight]
}

struct SpeechHighlight: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var start: TimeInterval
    var end: TimeInterval
    var reason: String
}

enum PaceType: String, Codable, CaseIterable {
    case slow = "느림"
    case comfortable = "적정"
    case fast = "빠름"
}

extension PaceType {
    var displayName: String {
        switch self {
        case .slow: return "느림"
        case .comfortable: return "적정"
        case .fast: return "빠름"
        }
    }
}

enum StabilityLevel: String, Codable, CaseIterable {
    case stable = "안정"
    case mixed = "변동"
    case unstable = "불안정"
}

extension StabilityLevel {
    var displayName: String {
        switch self {
        case .stable: return "안정"
        case .mixed: return "변동"
        case .unstable: return "불안정"
        }
    }
}

enum PauseType: String, Codable, CaseIterable {
    case smooth = "느림"
    case thinkingPause = "적정"
    case choppy = "빠름"
}

extension PauseType {
    var displayName: String {
        switch self {
        case .smooth: return "느림"
        case .thinkingPause: return "적정"
        case .choppy: return "빠름"
        }
    }
}

enum StructureType: String, Codable, CaseIterable {
    case clear = "구조 명확"
    case partial = "부분적으로 구조 있음"
    case unclear = "구조 흐림"
}

extension StructureType {
    var displayName: String {
        switch self {
        case .clear: return "구조 명확"
        case .partial: return "부분적으로 구조 있음"
        case .unclear: return "구조 흐림"
        }
    }
}

enum ConfidenceType: String, Codable, CaseIterable {
    case confident = "자신감 있음"
    case neutral = "보통"
    case hesitant = "조심/망설임"
}

extension ConfidenceType {
    var displayName: String {
        switch self {
        case .confident: return "자신감 있음"
        case .neutral: return "보통"
        case .hesitant: return "조심/망설임"
        }
    }
}
