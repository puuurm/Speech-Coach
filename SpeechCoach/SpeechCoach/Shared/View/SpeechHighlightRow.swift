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

    var onPlay: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))

                Text(item.coachDetail(recordDuration: duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                print("Tap Button")
                onPlay()
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
        .contentShape(Rectangle())
        .onTapGesture {
            print("onPlay")
            onPlay()
        } // 행 전체 탭으로도 재생
    }
}
