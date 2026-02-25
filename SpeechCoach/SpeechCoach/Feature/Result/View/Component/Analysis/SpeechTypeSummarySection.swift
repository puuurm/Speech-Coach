//
//  SpeechTypeSummarySection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/25/26.
//

import SwiftUI
import SpeechCoachAnalysis

struct SpeechTypeSummarySection: View {
    let speechType: SpeechTypeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("말하기 타입 요약")
                .font(.headline)

            Text(speechType.oneLiner)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text(speechType.paceType.label)
                Text("·")
                Text(speechType.paceStability.label)
            }
            .font(.footnote)
        }
    }
}
