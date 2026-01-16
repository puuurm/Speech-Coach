//
//  HighlightSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import SwiftUI

struct HighlightRow: View {
    let highlight: SpeechHighlight
    var onRequestPlay: ((TimeInterval) -> Void)? = nil

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                severityPill(highlight.severity)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(highlight.title)
                            .font(.callout.weight(.semibold))
                        Spacer()
                        Text(timeText(highlight.start, highlight.end))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(highlight.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? 3 : 2)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }

            if isExpanded {
                if !highlight.reason.isEmpty {
                    Text(highlight.reason)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .padding(.top, 2)
                }

                if let onRequestPlay {
                    Button {
                        onRequestPlay(highlight.start)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("이 구간 재생")
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy) { isExpanded.toggle() }
        }
    }

    private func severityPill(_ s: HighlightSeverity) -> some View {
        Text(s.label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    private func timeText(_ start: TimeInterval, _ end: TimeInterval) -> String {
        "\(toClock(start))-\(toClock(end))"
    }

    private func toClock(_ t: TimeInterval) -> String {
        let total = max(0, Int(t.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
