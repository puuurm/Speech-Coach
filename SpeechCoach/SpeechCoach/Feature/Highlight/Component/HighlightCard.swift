//
//  HighlightCard.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import SwiftUI

struct HighlightCard: View {
    let highlight: SpeechHighlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(highlight.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(timeRangeText(highlight))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(highlight.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            if let evidence = highlight.evidence, !evidence.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(evidence.prefix(2), id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
