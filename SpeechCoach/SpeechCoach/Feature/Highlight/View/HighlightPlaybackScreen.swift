//
//  HighlightPlaybackScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/24/25.
//

import SwiftUI
import AVKit

enum HighlightPlaybackMode {
    case videoOnly          // 기본: 영상만
    case videoWithInsight   // 확장: 영상 + 분석
}

struct HighlightPlaybackScreen: View {

    // MARK: - Input
    let videoURL: URL
    let highlight: SpeechHighlight
    let record: SpeechRecord

    // MARK: - State
    @State private var mode: HighlightPlaybackMode = .videoOnly
    @EnvironmentObject private var pc: PlayerController

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // ───────────────────────
                // Video Area
                // ───────────────────────
                ZStack(alignment: .topLeading) {
                    VideoPlayer(player: pc.player)
                        .ignoresSafeArea(edges: .top)

                    // 닫기 버튼 (항상 존재)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 12)
                }
                .frame(height: mode == .videoOnly ? nil : 280)

                // ───────────────────────
                // Insight Area (옵션)
                // ───────────────────────
                if mode == .videoWithInsight {
                    Divider()

                    HighlightInsightView(
                        highlight: highlight,
                        record: record
                    )
                    .transition(.move(edge: .bottom))
                }

                Spacer(minLength: 0)

                // ───────────────────────
                // Bottom Controls
                // ───────────────────────
                HighlightPlaybackControls(
                    mode: $mode
                )
            }
        }
        .onAppear {
            pc.load(url: videoURL)
            pc.seek(to: highlight.start, autoplay: true)
        }
        .onDisappear {
       
        }
    }
}
