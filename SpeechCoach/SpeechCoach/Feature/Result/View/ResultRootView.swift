//
//  ResultRootView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/4/26.
//

import SwiftUI

struct ResultRootView: View {
    @StateObject private var vm: ResultViewModel
    
    let recordID: UUID
    let highlightContext: HighlightListContext
    let playbackPolicy: HighlightPlaybackPolicy
    let onRequestPlay: (TimeInterval) -> Void
    @Binding var failedToSave: Bool
    
    init(
        recordID: UUID,
        highlightContext: HighlightListContext,
        playbackPolicy: HighlightPlaybackPolicy,
        onRequestPlay: @escaping (TimeInterval) -> Void,
        failedToSave: Binding<Bool>
    ) {
        self.recordID = recordID
        self.playbackPolicy = playbackPolicy
        self.highlightContext = highlightContext
        self.onRequestPlay = onRequestPlay
        self._failedToSave = failedToSave
        
        _vm = StateObject(wrappedValue: ResultViewModel(recordID: recordID))
    }
    
    var body: some View {
        ResultScreenLegacy(
            recordID: recordID,
            highlightContext: highlightContext,
            playbackPolicy: playbackPolicy,
            onRequestPlay: onRequestPlay,
            failedToSave: $failedToSave
        )
    }
}

