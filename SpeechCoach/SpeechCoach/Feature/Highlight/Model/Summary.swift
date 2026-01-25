//
//  ScriptMatchSummary.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import Foundation

struct ScriptMatchSummary: Hashable, Codable {
    enum ReadingStyle: String, Codable {
        case tooLiteral, balanced, keywordDriven
        var label: String {
            switch self {
            case .tooLiteral: return "너무 읽음"
            case .balanced: return "균형"
            case .keywordDriven: return "키워드 전달"
            }
        }
    }

    let readingStyle: ReadingStyle
    let readingScore: Double       // 0...1
    let keywordRetention: Double   // 0...1
}

struct NonverbalSummary: Hashable, Codable {
    enum Tension: String, Codable {
        case tense, neutral, relaxed
        var label: String {
            switch self {
            case .tense: return "경직"
            case .neutral: return "보통"
            case .relaxed: return "자연스러움"
            }
        }
    }

    let tension: Tension
    let expressionVariety: Double // 0...1
}

