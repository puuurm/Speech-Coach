//
//  TodayHomeworkRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/21/26.
//

import SwiftUI

struct TodayHomeworkRow: View {
    let drill: CoachDrill
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(drill.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(drill.durationSec / 60)분 연습")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        }
    }
}
