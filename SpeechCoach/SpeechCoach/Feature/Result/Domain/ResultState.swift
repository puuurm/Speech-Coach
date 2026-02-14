//
//  ResultState.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/4/26.
//

import Foundation
import SwiftUI
import SpeechCoachAnalysis

enum ResultState: Equatable {
    case loading
    case loaded(LoadedState)
    case failed(String)
}

struct LoadedState: Equatable {
    var record: SpeechRecord
    var metrics: SpeechMetrics
    
    var previousRecord: SpeechRecord?
    var previousMetrics: SpeechMetrics?
    
    var speechType: SpeechTypeSummary?
    var suggestions: [TemplateSuggestion]
    
    var note: NoteDraft
    
    var selectedTab: ResultTab = .feedback
    var showAdvanced: Bool = false
    var showQualitative: Bool = false
}

enum ResultTab: String, CaseIterable, Identifiable {
    case feedback = "노트"
    case analysis = "분석"
    var id: String { rawValue }
}

struct NoteDraft: Equatable {
    var editedTranscript: String = ""
    
    var introText: String = ""
    var strengthsText: String = ""
    var improvementsText: String = ""
    var nextStepsText: String = ""
    var practiceChecklistText: String = ""
    
    var qualitative: QualitativeMetrics = .neutral
}
