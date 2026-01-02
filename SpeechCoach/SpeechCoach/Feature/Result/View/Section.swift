//
//  Section.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import SwiftUI

struct ScriptMatchSection: View {
    let segments: [ScriptMatchSegment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("대본/발화 비교")
                .font(.title3.weight(.bold))

            if segments.isEmpty {
                // ✅ 스샷에서 지금 “텅 비어보이는” 문제 해결
                EmptyStateCard(
                    title: "대본/발화 비교를 만들려면 대본이 필요해요",
                    message: "대본을 추가하거나, 분석이 완료되면 구간별로 ‘일치/누락/추가’를 보여줄게요."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(segments) { seg in
                        ScriptMatchRow(segment: seg)
                    }
                }
            }
        }
    }
}

struct ScriptMatchRow: View {
    let segment: ScriptMatchSegment
    @State private var isExpanded: Bool = false

    var body: some View {
        Button {
            withAnimation(.snappy) { isExpanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(segment.start.toClock())–\(segment.end.toClock())")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    badge

                    Spacer(minLength: 8)

                    if let s = segment.similarity {
                        Text("\(Int(s * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }

                // ✅ 핵심만 한 줄 요약
                Text(oneLineSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        if let script = segment.scriptText, !script.isEmpty {
                            labeledText("대본", script)
                        }
                        if let spoken = segment.spokenText, !spoken.isEmpty {
                            labeledText("발화", spoken)
                        }
                        if !segment.keyPhrases.isEmpty {
                            keyPhrasesRow(segment.keyPhrases)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var badge: some View {
        HStack(spacing: 6) {
            Image(systemName: segment.kind.systemImage)
                .font(.caption.weight(.semibold))
            Text(segment.kind.badgeTitle)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.10))
        .clipShape(Capsule())
    }

    private var oneLineSummary: String {
        switch segment.kind {
        case .matched:
            return "대본과 거의 동일하게 전달했어요."
        case .paraphrased:
            return "표현은 달라도 메시지는 유지했어요."
        case .added:
            return "대본에 없는 내용이 추가됐어요."
        case .omitted:
            return "대본의 일부가 빠졌어요."
        }
    }

    private func labeledText(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func keyPhrasesRow(_ words: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(words, id: \.self) { w in
                    Text(w)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SummarySection: View {
    let record: SpeechRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요약")
                .font(.title3.weight(.bold))

            SummaryCardsRow(cards: summaryCards(for: record))
        }
    }

    private func summaryCards(for record: SpeechRecord) -> [SummaryCardModel] {
        [
            .init(title: "말하기 속도", value: "\(record.wordsPerMinute) WPM", caption: wpmCaption(record.wordsPerMinute)),
            .init(title: "톤/변동", value: "양호", caption: "단조로움 감지 기반"), // TODO: 실제 톤지표 연결
            .init(title: "필러", value: "\(record.fillerCount)", caption: record.fillerCount <= 3 ? "양호" : "주의"),

            // ✅ 추가(권장): 대본 일치율 / 표정 긴장도
            .init(title: "대본 일치", value: "—", caption: "대본 필요"),
            .init(title: "표정 긴장도", value: "—", caption: "영상 기반")
        ]
    }

    private func wpmCaption(_ wpm: Int) -> String {
        if wpm < 110 { return "조금 느림" }
        if wpm > 160 { return "조금 빠름" }
        return "적정"
    }
}

struct SummaryCardModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String
}

struct SummaryCardsRow: View {
    let cards: [SummaryCardModel]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(cards) { card in
                    SummaryCardView(model: card)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        // ✅ “가로 스크롤”임을 자연스럽게 보여주는 peek 여백
        .contentMargins(.trailing, 20, for: .scrollContent)
    }
}

struct SummaryCardView: View {
    let model: SummaryCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(model.value)
                .font(.title3.weight(.bold))
                .foregroundColor(.primary)

            Text(model.caption)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(width: 190, alignment: .leading) // ✅ 카드 폭 고정 → 잘림/레이아웃 흔들림 방지
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
