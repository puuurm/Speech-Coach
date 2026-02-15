//
//  ResultSectionAnchor.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/30/25.
//

import Foundation

enum ResultSectionAnchor: String, CaseIterable, Hashable, Identifiable {
    case summary
    case highlightPace
    case highlightTone
    case highlightFace
    case highlightScript
    case scriptCompare
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .summary:
            return "요약"
        case .highlightPace:
            return "속도"
        case .highlightTone:
            return "톤"
        case .highlightFace:
            return "표정"
        case .highlightScript:
            return "대본"
        case .scriptCompare:
            return "대본/발화 비교"
        }
    }
}
