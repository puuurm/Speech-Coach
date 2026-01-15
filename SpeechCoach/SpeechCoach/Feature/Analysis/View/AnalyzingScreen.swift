//
//  AnalyzingScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

//struct AnalyzingScreen: View {
//    let draft: SpeechDraft
//    let speechService: SpeechService
//    
//    let onComplete: (SpeechRecord) -> Void
//    
//    @EnvironmentObject private var router: NavigationRouter
//    @EnvironmentObject var recordStore: SpeechRecordStore
//    
//    @State private var isLoading = true
//    @State private var navigateToResult = false
//    @State private var record: SpeechRecord?
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack(spacing: 24) {
//            Spacer()
//            
//            if isLoading {
//                ProgressView()
//                    .scaleEffect(1.4)
//                
//                VStack(spacing: 8) {
//                    Text("텍스트로 변환 중입니다...")
//                        .font(.headline)
//                    Text("영상에서 음석을 추출하고, 말한 내용을 텍스트로 정리하고 있어요.")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 24)
//                }
//            } else if let errorMessage {
//                Text("분석에 실패했어요.")
//                    .font(.headline)
//                Text(errorMessage)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal, 24)
//            }
//            Spacer()
//        }
//        .navigationTitle("분석 중")
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationDestination(item: $record) { record in
//            ResultScreen(
//                recordID: record.id,
//                playbackPolicy: .hidden,
//                highlightContext: <#HighlightListContext#>,
//                onRequestPlay: { _ in}
//            )
//        }
//        .task {
//            await runAnalysis()
//        }
//
//    }
//    
//    private func runAnalysis() async {
//        do {
//            print("🎧 Start transcribe:", draft.videoURL)
//            let rawTranscript = try await speechService.transcribe(videoURL: draft.videoURL)
//            let cleaned = TranscriptCleaner.cleaned(rawTranscript)
//            
//            let title = SpeechTitleBuilder.makeTitle(
//                transcript: cleaned,
//                createdAt: Date()
//            )
//            
//            let analyzer = TranscriptAnalyzer()
//            let wpm = analyzer.wordsPerMinute(
//                transcript: cleaned,
//                duration: draft.duration
//            )
//            let fillerWordsDict = analyzer.fillerWordsDict(from: cleaned)
//            let fillers = analyzer.fillerCount(in: cleaned)
//            let relativePath = try VideoStore.shared.importToSandbox(sourceURL: draft.videoURL, recordID: draft.id)
//            
//            let now = Date()
//            
//            let newRecord = SpeechRecord(
//                id: draft.id,
//                createdAt: now,
//                title: title,
//                duration: draft.duration,
//                summaryWPM: wpm,
//                summaryFillerCount: fillers,
//                metricsGeneratedAt: now,
//                transcript: cleaned,
//                studentName: nil,
//                videoRelativePath: relativePath,
//                note: nil,
//                insight: nil,
//                highlights: []
//            )
//            
//            let newMetrics = SpeechMetrics(
//                recordID: draft.id,
//                generatedAt: now,
//                wordsPerMinute: wpm,
//                fillerCount: fillers,
//                fillerWords: fillerWordsDict,
//                paceVariability: nil,
//                spikeCount: nil
//            )
//            
//            await MainActor.run {
//                recordStore.upsertBundle(
//                    record: newRecord,
//                    metrics: newMetrics
//                )
//                self.record = newRecord
//                self.isLoading = false
//                self.navigateToResult = true
//                onComplete(newRecord)
//            }
//        } catch {
//            print("❌ runAnalysis error:", error)
//            await MainActor.run {
//                self.isLoading = false
//                self.errorMessage = error.localizedDescription
//            }
//        }
//    }
//}
//
//#Preview {
//    AnalyzingScreen(
//        draft: .init(
//            id: UUID(),
//            title: "예시 발표 영상",
//            duration: 120,
//            videoURL: URL(fileURLWithPath: "/dev/null")
//        ),
//        speechService: MockSpeechService(),     
//        onComplete: { record in
//            print("완료: \(record.title)")
//        }
//    )
//}
