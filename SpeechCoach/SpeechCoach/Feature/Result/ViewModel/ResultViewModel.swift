//
//  ResultViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/4/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ResultViewModel: ObservableObject {
    @Published private(set) var state: ResultState = .loading
    
    private let recordID: UUID
    
    init(recordID: UUID) {
        self.recordID = recordID
    }
    
    // MARK: - Lifecycle
    
    func load(using store: SpeechRecordStore, analyzer: ResultAnalyzing = ResultAnalyzer()) async {
        state = .loading
        
        do {
            guard let record = store.record(with: recordID) else {
                state = .failed("기록을 찾을 수 없어요.")
                return
            }
            let previousRecord = store.previousRecord(before: record.id)
            
            guard let metrics = store.metrics(with: record.id) else { return }
            
            let analysis = analyzer.analyze(
                ResultAnalysisInput(
                    duration: record.duration,
                    transcript: record.transcript,
                    segments: record.insight?.transcriptSegments,
                    metrics: metrics
                ))
            
            let loaded = LoadedState(
                record: record,
                metrics: metrics,
                previousRecord: previousRecord,
                previousMetrics: nil,
                speechType: analysis.speechType,
                suggestions: [],
                note: hydrateNote(from: record)
            )
            state = .loaded(loaded)
        } catch {
            state = .failed("불러오기 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Actions
    
    func selectTab(_ tab: ResultTab) {
        updateLoaded { $0.selectedTab = tab }
    }
    
    func applySuggestion(_ suggestion: TemplateSuggestion) {
        updateLoaded { loaded in
            let sentence = "• \(suggestion.body)"
            switch suggestion.category {
            case .strengths:
                loaded.note.strengthsText = appendLine(loaded.note.strengthsText, sentence)
            case .improvements:
                loaded.note.improvementsText = appendLine(loaded.note.improvementsText, sentence)
            case .nextStep:
                if suggestion.isActionItem {
                    loaded.note.practiceChecklistText = appendLine(loaded.note.practiceChecklistText, sentence)
                } else {
                    loaded.note.nextStepsText = appendLine(loaded.note.nextStepsText, sentence)
                }
            }
        }
    }
    
    func updateNote(_ update: (inout NoteDraft) -> Void) {
        updateLoaded { loaded in
            update(&loaded.note)
        }
    }
    
    func save(using recordStore: SpeechRecordStore) async throws {
        guard case var .loaded(loaded) = state else { return }
        
        let note = normalizedNote(loaded.note)
        
        recordStore.updateNotes(
            for: loaded.record.id,
            intro: note.introText,
            strenghts: note.strengthsText,
            improvements: note.improvementsText,
            nextStep: note.nextStepsText,
            checklist: note.practiceChecklistText
        )
        
        recordStore.updateQualitative(for: loaded.record.id, metrics: note.qualitative)
        
        if !note.editedTranscript.isEmpty,
           note.editedTranscript != loaded.record.transcript {
            AutoCorrectionStore.shared.learn(from: loaded.record.transcript, edited: note.editedTranscript)
        }
        
        try await recordStore.persist()
        
        loaded.note = note
        state = .loaded(loaded)
    }
}

// MARK: - Helpers
private extension ResultViewModel {
    func updateLoaded(_ mutate: (inout LoadedState) -> Void) {
        guard case var .loaded(loaded) = state else { return }
        mutate(&loaded)
        state = .loaded(loaded)
    }
    
    func appendLine(_ original: String, _ newLine: String) -> String {
        if original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return newLine
        } else {
            return (original + "\n" + newLine)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func hydrateNote(from record: SpeechRecord) -> NoteDraft {
        var draft = NoteDraft()
        
        if let note = record.note {
            draft.introText = note.intro
            draft.strengthsText = note.strengths
            draft.improvementsText = note.improvements
            draft.nextStepsText = note.nextStep
            draft.practiceChecklistText = note.checklist ?? ""
        }
        
        // draft.qualitative = record.qualitative ?? .neutral
        
        return draft
    }
    
    func normalizedNote(_ note: NoteDraft) -> NoteDraft {
        var n = note
        n.introText = n.introText.trimmingCharacters(in: .whitespacesAndNewlines)
        n.strengthsText = n.strengthsText.trimmingCharacters(in: .whitespacesAndNewlines)
        n.improvementsText = n.improvementsText.trimmingCharacters(in: .whitespacesAndNewlines)
        n.nextStepsText = n.nextStepsText.trimmingCharacters(in: .whitespacesAndNewlines)
        n.practiceChecklistText = n.practiceChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        n.editedTranscript = n.editedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        return n
    }
}
