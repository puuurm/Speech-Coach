//
//  SpeakingTypeSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI

enum SpeakingTypeAction {
    case copy
    case insertMemo(String)
    case playHighlight(SpeechHighlight)
    case selectHighlight(SpeechHighlight)
}

struct SpeakingTypeSection: View {
    let record: SpeechRecord
    let speechType: SpeechTypeSummary?
    let playbackPolicy: HighlightPlaybackPolicy
    let highlightContext: HighlightListContext
    let send: (SpeakingTypeAction) -> Void
    
    @State private var expanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("말하기 타입 요약")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(expanded ? "접기" : "펼치기")
//                        Image(systemName: "chevron.down")
//                            .rotationEffect(.degrees(expanded ? 180 : 0))
                    }
                    .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.secondary)

            }

            if let speechType {
                expandableSummaryCard(
                    speechType: speechType,
                    expanded: expanded
                )
                highlightsSection(
                    highlights: record.highlights,
                    context: highlightContext,
                    playbackPolicy: playbackPolicy
                )
                
            } else {
                Text("요약을 만들 데이터가 아직 부족해요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension SpeakingTypeSection {
    func expandableSummaryCard(
        speechType: SpeechTypeSummary,
        expanded: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(speechType.oneLiner)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            if expanded {
                Divider()
                    .opacity(0.4)
                VStack(alignment: .leading, spacing: 6) {
                    Text("왜 이렇게 판단했나요?")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(speechType.displayReasons(), id: \.self) { reason in
                        Text("• \(reason)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.18), value: expanded)
    }
    
    @ViewBuilder
    private func highlightsSection(
        highlights: [SpeechHighlight],
        context: HighlightListContext,
        playbackPolicy: HighlightPlaybackPolicy
    ) -> some View {
        if highlights.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                Text("체크할 구간")
                    .font(.subheadline.weight(.semibold))

                ForEach(highlights.prefix(3)) { h in
                    SpeechHighlightRow(
                        item: h,
                        duration: record.duration,
                        context: context,
                        playbackPolicy: playbackPolicy,
                        onPlay: {
                            send(.playHighlight(h))
                        },
                        onSelect: (context == .feedbackAnalysis || context == .homeAnalysis) ? {
                            send(.selectHighlight(h))
                        } : nil
                    )
                }
            }
        }
    }

}
