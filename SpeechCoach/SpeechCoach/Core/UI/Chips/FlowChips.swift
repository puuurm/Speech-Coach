//
//  FlowChips.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/16/25.
//

import SwiftUI

struct FlowChips<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                content
            }
        }
    }
}

struct SignalTemplateChips: View {

    let suggestions: [TemplateSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            if suggestions.isEmpty {
                Text("추천을 생성할 데이터가 아직 부족해요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(suggestions) { suggestion in
                    TemplateChip(suggestion: suggestion)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct TemplateChip: View {

    let suggestion: TemplateSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 8) {
                CategoryBadge(category: suggestion.category)

                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()
            }

            Text(suggestion.body)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct CategoryBadge: View {

    let category: TemplateSuggestion.SuggestionCategory

    var body: some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(background)
            )
    }

    private var label: String {
        switch category {
        case .strengths:
            return "강점"
        case .improvements:
            return "개선"
        case .nextStep:
            return "다음 단계"
        }
    }

    private var background: Color {
        switch category {
        case .strengths:
            return Color.green.opacity(0.15)
        case .improvements:
            return Color.orange.opacity(0.18)
        case .nextStep:
            return Color.blue.opacity(0.18)
        }
    }

    private var foreground: Color {
        switch category {
        case .strengths:
            return .green
        case .improvements:
            return .orange
        case .nextStep:
            return .blue
        }
    }
}
