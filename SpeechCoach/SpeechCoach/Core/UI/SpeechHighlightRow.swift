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
    let context: HighlightListContext
    let playbackPolicy: HighlightPlaybackPolicy
    var onPlay: (() -> Void)? = nil
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitleText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            trailingAccessory
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            guard context == .feedbackAnalysis else { return }
            onSelect?()
        }
    }
}

extension SpeechHighlightRow {
    private var subtitleText: String {
        let time = timeRangeText(item)
        let desc = item.detail.isEmpty ? item.reason : item.detail
        return "\(time) · \(desc)"
    }
    
    @ViewBuilder
    private var trailingAccessory: some View {
        if context == .feedbackAnalysis {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.top, 2) // 상단 정렬 미세 조정(선택)
        }
        else if context != .homeAnalysis,
                case let .playable(play) = playbackPolicy {
            Button {
                play(item.start)
            } label: {
                Text("재생")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        } else {
            EmptyView()
        }
    }
    
}
