//
//  AnalysisTab.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI
import SpeechCoachAnalysis

struct AnalysisTab: View {
    @Environment(\.crashLogger) private var crashLogger
    
    let record: SpeechRecord
    let metrics: SpeechMetrics
    
    let previousRecord: SpeechRecord?
    let previousMetrics: SpeechMetrics?
    
    let speechType: SpeechTypeSummary?
    let playbackPolicy: HighlightPlaybackPolicy
    let highlightContext: HighlightListContext
    
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
                playbackPolicy: playbackPolicy,
                highlightContext: highlightContext
            ) { action in
                switch action {
                case .copy:
                    guard let speechType else { return }
                    UIPasteboard.general.string = speechType.clipboardText(for: record)
                    showCopyAlert = true
                case .insertMemo(let snippet):
                    insertIntoImprovements(snippet)
                case .playHighlight(let highlight):
                    crashLogger.setValue(highlight.id.uuidString, forKey: "highlight_id")
                    crashLogger.log("Action playHighlight id=\(highlight.id) start=\(highlight.start) end=\(highlight.end)")
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
        }
    }
}

