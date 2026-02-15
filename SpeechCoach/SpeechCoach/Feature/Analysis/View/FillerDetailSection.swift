//
//  FillerDetailSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI

struct FillerDetailSection: View {
    let metrics: SpeechMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("습관어 상세")
                .font(.headline)
            
            let items = metrics.fillerWords.sorted { $0.value < $1.value }
            
//            if items.isEmpty {
//                Text("추출된 필러 단어가 없어요.")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            } else {
//                Text(
//                    items
//                        .map { "\($0.key)(\($0.value))" }
//                        .joined(separator: " · ")
//                )
//                .font(.subheadline)
//            }
            
            ForEach(items, id: \.0) { word, count in
                HStack {
                    Text(word)
                    Spacer()
                    Text("\(count)회")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
    }
}
