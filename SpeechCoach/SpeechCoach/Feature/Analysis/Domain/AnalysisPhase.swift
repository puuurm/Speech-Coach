//
//  AnalysisPhase.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/9/25.
//

import Foundation

enum AnalysisPhase: Equatable {
    case idle
    case analyzing
    case waitingForPlaybackEnd
    case ready
    case failed(UserFacingError)
}

struct UserFacingError: Equatable {
    let title: String
    let message: String
    let suggestion: String?
}
