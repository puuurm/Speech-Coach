//
//  TranscriptSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI

struct TranscriptSection: View {
    let record: SpeechRecord
    
    @State private var showAllTranscript: Bool = false
    
    private var shouldHideTranscript: Bool {
        TranscriptQuality.shouldHide(
            transcript: record.transcript,
            segments: record.insight?.transcriptSegments
        )
    }
    
    private var transcriptText: String {
        if shouldHideTranscript {
            return TranscriptQuality.hideMessage
        }
        return record.transcript.isEmpty ? "인식된 텍스트가 없어요." : record.transcript
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("전체 스크립트")
                    .font(.headline)
                Spacer()
                
                if !shouldHideTranscript {
                    Button(showAllTranscript ? "접기" : "펼치기") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showAllTranscript.toggle()
                        }
                    }
                    .font(.caption.weight(.semibold))
                }
            }
            
            Text(shouldHideTranscript
                       ? "텍스트 변환 정확도가 낮아 스크립트를 표시하지 않았어요."
                       : "자동 인식 초안이에요. 중요한 문장은 영상과 함께 확인해 주세요.")
                      .font(.caption2)
                      .foregroundColor(.secondary)
            
            let text = record.transcript.isEmpty ? "인식된 텍스트가 없어요." : record.transcript
            
            if showAllTranscript && !shouldHideTranscript {
                ScrollView {
                    Text(transcriptText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(minHeight: 180)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            } else {
                Text(transcriptText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(shouldHideTranscript ? nil : 5)
                    .truncationMode(.tail)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }
        }
    }
}
