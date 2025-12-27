//
//  AnalyzingScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

struct AnalyzingScreen: View {
    let draft: SpeechDraft
    let speechService: SpeechService
    
    let onComplete: (SpeechRecord) -> Void
    
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject var recordStore: SpeechRecordStore
    
    @State private var isLoading = true
    @State private var navigateToResult = false
    @State private var record: SpeechRecord?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.4)
                
                VStack(spacing: 8) {
                    Text("텍스트로 변환 중입니다...")
                        .font(.headline)
                    Text("영상에서 음석을 추출하고, 말한 내용을 텍스트로 정리하고 있어요.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else if let errorMessage {
                Text("분석에 실패했어요.")
                    .font(.headline)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .navigationTitle("분석 중")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $record) { record in
            ResultScreen(
                record: record,
                playbackPolicy: .hidden,
                onRequestPlay: { _ in}
            )
        }
        .task {
            await runAnalysis()
        }

    }
    
    private func runAnalysis() async {
        do {
            print("🎧 Start transcribe:", draft.videoURL)
            let rawTranscript = try await speechService.transcribe(videoURL: draft.videoURL)
            let cleaned = TranscriptCleaner.cleaned(rawTranscript)
            
            let title = SpeechTitleBuilder.makeTitle(
                transcript: cleaned,
                createdAt: Date()
            )
            
            let analyzer = TranscriptAnalyzer()
            let wpm = analyzer.wordsPerMinute(
                transcript: cleaned,
                duration: draft.duration
            )
            let fillerWordsDict = analyzer.fillerWordsDict(from: cleaned)
            let fillers = analyzer.fillerCount(in: cleaned)
            let relativePath = try await VideoStore.shared.importToSandbox(sourceURL: draft.videoURL, recordID: draft.id)
            
            var newRecord = SpeechRecord(
                id: draft.id,
                createdAt: Date(),
                title: title,
                duration: draft.duration,
                wordsPerMinute: wpm,
                fillerCount: fillers,
                transcript: cleaned,
                fillerWords: fillerWordsDict,
                studentName: "희정님",
                videoRelativePath: relativePath,
                note: nil,
                insight: nil,
                highlights: []
            )
            
            await MainActor.run {
                recordStore.add(newRecord)
                
                self.record = newRecord
                self.isLoading = false
                self.navigateToResult = true
                onComplete(newRecord)
            }
        } catch {
            print("❌ runAnalysis error:", error)
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    

}

#Preview {
    AnalyzingScreen(
        draft: .init(
            id: UUID(),
            title: "예시 발표 영상",
            duration: 120,
            videoURL: URL(fileURLWithPath: "/dev/null")
        ),
        speechService: MockSpeechService(),     
        onComplete: { record in
            print("완료: \(record.title)")
        }
    )
}
