//
//  FeedbackTemplate.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/14/25.
//

import Foundation

struct FeedbackTemplate: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let intro: String
    let strengths: String
    let improvements: String
    let nextStep: String
}

enum FeedbackTemplateBuilder {
    static func build(for record: SpeechRecord) -> [FeedbackTemplate] {
        return []
    }
}
