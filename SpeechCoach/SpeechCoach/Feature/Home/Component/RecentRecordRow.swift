//
//  RecentRecordRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

struct RecentRecordRow: View {
    let record: SpeechRecord
    
    private var isTranscriptUnreliable: Bool {
        TranscriptQuality.shouldHide(
            transcript: record.transcript,
            segments: record.insight?.transcriptSegments
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 51, height: 51)
                .overlay(
                    Image(systemName: "video")
                        .font(.title3)
                        .foregroundColor(.secondary)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(record.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if isTranscriptUnreliable {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                        Text("텍스트 인식이 불안정했어요")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                HStack(spacing: 10) {

                    metric(icon: "clock", text: durationString(record.duration))
                    if let wpm = record.summaryWPM {
                        metric(icon: "speedometer", text: "\(wpm) wpm")
                    } else {
                        metric(icon: "speedometer", text: "— wpm")
                    }
                    
                    if let fillerCount = record.summaryFillerCount {
                        metric(icon: "quote.bubble", text: "\(fillerCount)")
                    } else {
                        metric(icon: "quote.bubble", text: "—")
                    }
                }
                .lineSpacing(2)
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }

    private func metric(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .baselineOffset(1)
    }
}
