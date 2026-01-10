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
    let send: (SpeakingTypeAction) -> Void
    
    @State private var expanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("말하기 타입 요약")
                    .font(.headline)

                Spacer()

//                Button("요약 복사") {
//                    send(.copy)
//                }
//                .font(.caption.weight(.semibold))
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(expanded ? "접기" : "자세히 보기")
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            if let speechType {
                oneLinerCard(text: speechType.oneLiner)
                
                if expanded {
                    VStack(alignment: .leading, spacing: 6) {
                        row("속도", "\(speechType.paceType.displayName) · \(speechType.paceStability.displayName)")
                        row("쉬는 습관", speechType.pauseType.displayName)
                        row("구조", speechType.structureType.displayName)
                        row("자신감", speechType.confidenceType.displayName)
                    }
                }
//
//                Button {
//                    let snippet = speechType.memoSnippet(for: record)
//                    send(.insertMemo(snippet))
//                } label: {
//                    Label("개선 메모에 요약 삽입", systemImage: "plus.circle")
//                        .font(.caption.weight(.semibold))
//                }
//                .buttonStyle(.plain)
//                .foregroundColor(.accentColor)
                
                highlightsSection(highlights: record.highlights)
                
            } else {
                Text("요약을 만들 데이터가 아직 부족해요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension SpeakingTypeSection {
    private func oneLinerCard(text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
    }
    
    @ViewBuilder
    private func highlightsSection(highlights: [SpeechHighlight]) -> some View {
        if highlights.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                Text("체크할 구간")
                    .font(.subheadline.weight(.semibold))
                
                ForEach(highlights.prefix(3)) { highlight in
                    SpeechHighlightRow(
                        item: highlight,
                        duration: record.duration,
                        playbackPolicy: playbackPolicy,
                        onPlay: {
//                            presentCoachAssistant(for: h)
                            send(.playHighlight(highlight))
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
//                        selectedHighlight = h
                        send(.selectHighlight(highlight))
                    }
                }
            }
        }
    }
    
    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .frame(width: 70, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}
