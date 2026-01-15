//
//  AnalysisTab.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI

struct AnalysisTab: View {
    let record: SpeechRecord
    let metrics: SpeechMetrics
    
    let previousRecord: SpeechRecord?
    let previousMetrics: SpeechMetrics?
    
    let speechType: SpeechTypeSummary?
    let playbackPolicy: HighlightPlaybackPolicy
    
    @Binding var selectedHighlight: SpeechHighlight?
    @State private var showCopyAlert: Bool = false
    @State private var showAdvanced: Bool = false
    
    let insertIntoImprovements: (String) -> Void
    let presentCoachAssistant: (SpeechHighlight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MetricsSection(metrics: metrics)
            
            SpeakingTypeSection(
                record: record,
                speechType: speechType,
                playbackPolicy: playbackPolicy
            ) { action in
                switch action {
                case .copy:
                    guard let speechType else { return }
                    UIPasteboard.general.string = speechType.clipboardText(for: record)
                    showCopyAlert = true
                case .insertMemo(let snippet):
                    insertIntoImprovements(snippet)
                case .playHighlight(let highlight):
                    presentCoachAssistant(highlight)
                case .selectHighlight(let highlight):
                    selectedHighlight = highlight
                }
            }
            
            if let prevMetrics = previousMetrics {
                ProgressSection(current: metrics, previous: prevMetrics)
            }
            
            if !metrics.fillerWords.isEmpty {
                FillerDetailSection(metrics: metrics)
            }
            
            TranscriptSection(record: record)
            
            DisclosureGroup(
                isExpanded: $showAdvanced,
                content: {
                    Text("※ 자동 인식 초안이라 부정확할 수 있어요. 중요한 문장은 영상과 함께 확인해주세요.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                },
                label: {
                    HStack {
                        Text("안내")
                            .font(.headline)
                        Spacer()
                        Text(showAdvanced ? "접기" : "펼치기")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            )
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground)))
        }
    }
}

