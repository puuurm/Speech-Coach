//
//  TemplateSuggestion.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/14/25.
//

import Foundation

struct TemplateSuggestion: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let body: String
    let category: SuggestionCategory
    
    init(title: String, body: String, category: SuggestionCategory) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.category = category
    }
    
    enum SuggestionCategory: String, Codable, Hashable {
        case strengths
        case improvements
        case nextStep
    }
}
