//
//  ScriptMatchSegment.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import Foundation

struct ScriptMatchSegment: Identifiable, Hashable, Codable {
    enum Kind: String, Codable, CaseIterable, Hashable {
         case matched
         case paraphrased
         case added
         case omitted
     }
    
    let id: UUID
    let start: TimeInterval
    let end: TimeInterval
    
    
    let kind: Kind
    let similarity: Double?
    let scriptText: String?
    let spokenText: String?
    let keyPhrases: [String]
}

extension ScriptMatchSegment.Kind {
    var badgeTitle: String {
        switch self {
        case .matched: return "일치"
        case .paraphrased: return "의미유사"
        case .added: return "추가"
        case .omitted: return "누락"
        }
    }

    var systemImage: String {
        switch self {
        case .matched: return "checkmark.seal"
        case .paraphrased: return "arrow.triangle.2.circlepath"
        case .added: return "plus.circle"
        case .omitted: return "minus.circle"
        }
    }
}
