//
//  AnalysisEvent.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/1/26.
//

import Foundation

enum AnalysisEvent {
    case startTapped
    case analysisSucceeded(playbackEnded: Bool, record: SpeechRecord, metrics: SpeechMetrics)
    case playbackEnded
    case openResultNow
    case cancelled
    case failed(UserFacingError)
    case reset
}
