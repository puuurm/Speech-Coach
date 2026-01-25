//
//  AnchorChips.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/30/25.
//

import SwiftUI

struct AnchorChips: View {
    @Binding var selected: ResultSectionAnchor
    let items: [ResultSectionAnchor]
    let onTap: (ResultSectionAnchor) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    Button {
                        selected = item
                        onTap(item)
                    } label: {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selected == item ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
