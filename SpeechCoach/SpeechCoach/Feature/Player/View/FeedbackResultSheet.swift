//
//  FeedbackResultSheet.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/25/26.
//

import AlertToast
import SwiftUI

struct FeedbackResultSheet: View {
    let recordID: UUID
    let shouldShowFullFlowBanner: Bool
    
    let onPlaybackStart: (TimeInterval) -> Void
    let onRequestPlay: (TimeInterval) -> Void
    let onTapWatchVideo: () -> Void
    let onTapDontShowAgain: () -> Void
    
    @Binding var failedToSave: Bool
    
    @EnvironmentObject private var pc: PlayerController
    
    var body: some View {
        NavigationStack {
            ResultScreen(
                recordID: recordID,
                highlightContext: .feedbackAnalysis,
                playbackPolicy: .playable { start in
                    onPlaybackStart(start)
                },
                onRequestPlay: { sec in
                    onRequestPlay(sec)
                },
                failedToSave: $failedToSave
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                if shouldShowFullFlowBanner {
                    FullFlowHintBanner(
                        onTapWatchVideo: onTapWatchVideo,
                        onTapDontShowAgain: onTapDontShowAgain
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
            }
        }
        .toast(isPresenting: $failedToSave, offsetY: 15) {
            AlertToast(
                displayMode: .hud,
                type: .error(.red),
                title: "저장하지 못했어요"
            )
        }
        .onAppear {
            failedToSave = false
        }
    }
}
