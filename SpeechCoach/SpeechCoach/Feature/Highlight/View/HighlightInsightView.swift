//
//  HighlightInsightView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/24/25.
//

import SwiftUI

struct HighlightInsightView: View {
    let highlight: SpeechHighlight
    let record: SpeechRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                Text(highlight.title)
                    .font(.headline)

                Text(highlight.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Divider()

                Text("코칭 포인트")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(highlight.reason)
                    .font(.body)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}
