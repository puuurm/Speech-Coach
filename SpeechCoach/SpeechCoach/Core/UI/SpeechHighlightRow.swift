//
//  SpeechHighlightRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/17/25.
//

import SwiftUI
import AVKit

struct SpeechHighlightRow: View {
    let item: SpeechHighlight
    let duration: TimeInterval
    let playbackPolicy: HighlightPlaybackPolicy
    var onPlay: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))

                Text(item.coachLineText())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            switch playbackPolicy {
            case .hidden:
                EmptyView()
            case .playable(let onPlay):
                Button {
                    onPlay(item.start)
                } label: {
                    Text("재생")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay?()
        }
    }
}
