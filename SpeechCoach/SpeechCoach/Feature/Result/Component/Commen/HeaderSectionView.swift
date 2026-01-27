//
//  HeaderSectionView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/15/26.
//

import SwiftUI

struct HeaderSectionView: View {
    let record: SpeechRecord
    let isTranscriptUnreliable: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cleanTitle(from: record.title))
                .font(.title3.weight(.semibold))
            
            HStack(spacing: 8) {
                Text(record.createdAt.headerDisplayString)
                Text("·")
                Text(durationString(record.duration))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
