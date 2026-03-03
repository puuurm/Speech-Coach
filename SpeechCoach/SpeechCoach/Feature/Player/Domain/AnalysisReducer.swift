//
//  AnalysisReducer.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/3/26.
//

import Foundation

struct AnalysisState {
    var phase: AnalysisPhase
    var playbackEnded: Bool
    var analyzedRecord: SpeechRecord?
    var analyzedMetrics: SpeechMetrics?
}

enum AnalysisReducer {
    static func reduce(_ state: inout AnalysisState, _ event: AnalysisEvent) {
        switch (state.phase, event) {
        case (.idle, .startTapped):
            state.phase = .analyzing
            
        case (.analyzing, .analysisSucceeded(let ended, let record, let metrics)):
            state.analyzedRecord = record
            state.analyzedMetrics = metrics
            state.phase = ended ? .ready : .waitingForPlaybackEnd
            
        case (.waitingForPlaybackEnd, .playbackEnded),
            (.waitingForPlaybackEnd, .openResultNow):
            state.phase = .ready
            
        case (_, .failed(let err)):
            state.phase = .failed(err)
            
        case (_, .cancelled):
            state.phase = .idle
            
        case (_, .reset):
            state.analyzedRecord = nil
            state.analyzedMetrics = nil
            state.playbackEnded = false
            state.phase = .idle
        
        default:
            break
        }
    }
}
