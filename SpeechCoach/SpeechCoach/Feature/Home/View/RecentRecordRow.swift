//
//  RecentRecordRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

struct RecentRecordRow: View {
    let record: SpeechRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // 썸네일
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 51, height: 51)
                .overlay(
                    Image(systemName: "video")
                        .font(.title3)
                        .foregroundColor(.secondary)
                )

            // 텍스트 영역
            VStack(alignment: .leading, spacing: 6) {
                // 제목
                Text(record.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // 메트릭 라인
                HStack(spacing: 10) {

                    metric(icon: "clock", text: durationString(record.duration))
                    metric(icon: "speedometer", text: "\(record.wordsPerMinute) wpm")
                    metric(icon: "quote.bubble", text: "필러 \(record.fillerCount)")
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
        .font(.caption)               // ← caption2보다 훨씬 안정적
        .foregroundColor(.secondary)
        .baselineOffset(1)            // ← 글자 깨짐 방지
    }
}
