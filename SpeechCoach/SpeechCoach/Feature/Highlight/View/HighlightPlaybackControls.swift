//
//  HighlightPlaybackControls.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/24/25.
//

import SwiftUI

struct HighlightPlaybackControls: View {
    @Binding var mode: HighlightPlaybackMode

    var body: some View {
        HStack(spacing: 12) {

            Spacer()

            Button {
                withAnimation(.easeInOut) {
                    mode = (mode == .videoOnly) ? .videoWithInsight : .videoOnly
                }
            } label: {
                Text(mode == .videoOnly ? "분석 보기" : "분석 닫기")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .background(.black.opacity(0.85))
    }
}
