//
//  SummaryCard.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let footnote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline.weight(.semibold))

            Text(footnote)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 160, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

