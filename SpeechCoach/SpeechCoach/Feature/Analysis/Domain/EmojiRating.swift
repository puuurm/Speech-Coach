//
//  EmojiRating.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/11/25.
//

import Foundation

enum EmojiRating: Int, CaseIterable, Codable, Identifiable {
    case veryLow  = 1   // 많이 아쉬움
    case low      = 2   // 개선 필요
    case neutral  = 3   // 보통
    case high     = 4   // 좋은 편
    case veryHigh = 5   // 매우 좋음
    
    var id: Int { rawValue }
    
    var emoji: String {
        switch self {
        case .veryLow:  return "😣"
        case .low:      return "😕"
        case .neutral:  return "😐"
        case .high:     return "🙂"
        case .veryHigh: return "😄"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .veryLow:  return "아쉬움"
        case .low:      return "개선"
        case .neutral:  return "보통"
        case .high:     return "좋음"
        case .veryHigh: return "매우 좋음"
        }
    }
}
