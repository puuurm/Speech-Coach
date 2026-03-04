//
//  DefaultSpeechAnalysisPipeline.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/27/26.
//

import Foundation
import Speech
import SpeechCoachAnalysis

class DefaultSpeechAnalysisPipeline: SpeechAnalysisPipeline {
    
    private let speechService: RealSpeechService
    private let analyzer: TranscriptAnalyzer
    private let crashLogger: CrashLogging
    
    init(
        speechService: RealSpeechService,
        analyzer: TranscriptAnalyzer,
        crashLogger: CrashLogging
    ) {
        self.speechService = speechService
        self.analyzer = analyzer
        self.crashLogger = crashLogger
    }
    
    func cancel() {
        speechService.cancelRecognitionIfSupported()
        crashLogger.log("DefaultSpeechAnalysisPipeline: cancel requested")
    }
    
    func run(videoURL: URL, durationHint: TimeInterval) async throws -> (SpeechRecord, SpeechMetrics) {
        crashLogger.setValue("runAnalysis_start", forKey: "analysis_phase")
        crashLogger.log("DefaultSpeechAnalysisPipeline: run start video=\(videoURL.lastPathComponent)")

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))!
        let audioURL = try await speechService.exportAudio(from: videoURL)
        
        crashLogger.setValue("recognizeDetailed", forKey: "analysis_phase")
        let transcriptResult = try await speechService.recognizeDetailed(url: audioURL, with: recognizer)
        
        let cleaned = transcriptResult.cleanedText
        let segments = transcriptResult.segments
        
        let duration: TimeInterval = {
            if durationHint > 0 {
                return durationHint
            } else {
                let asset = AVAsset(url: videoURL)
                let seconds = CMTimeGetSeconds(asset.duration)
                return seconds.isFinite ? seconds : 0
            }
        }()
        
        let wpm = analyzer.wordsPerMinute(transcript: cleaned, duration: duration)
        let fillerDict = analyzer.fillerWordsDict(from: cleaned)
        let fillerTotal = fillerDict.values.reduce(0, +)
        
        let recordID = UUID()
        crashLogger.setValue(recordID.uuidString, forKey: "record_id")
        
        crashLogger.setValue("importVideo", forKey: "analysis_phase")
        let relative = try VideoStore.shared.importToSandbox(sourceURL: videoURL, recordID: recordID)
        
        let now = Date()
        
        let hide = TranscriptQualityChecker.shouldHide(
            transcript: cleaned,
            segments: segments
        )

        let title = SpeechTitleBuilder.makeTitle(
            transcript: cleaned,
            createdAt: now,
            canUseTranscript: !hide
        )
        
        var record = SpeechRecord(
            id: recordID,
            createdAt: now,
            title: title,
            duration: duration,
            summaryWPM: wpm,
            summaryFillerCount: fillerTotal,
            metricsGeneratedAt: now,
            transcript: cleaned,
            studentName: nil,
            videoRelativePath: relative,
            note: nil,
            insight: .init(
                oneLiner: "",
                problemSummary: "",
                qualitative: nil,
                transcriptSegments: segments,
                updatedAt: now
            ),
            highlights: []
        )

        crashLogger.setValue("buildHighlights", forKey: "analysis_phase")
        let highlights = SpeechHighlightBuilder.makeHighlights(
            duration: duration,
            segments: record.insight?.transcriptSegments ?? []
        )
        record.highlights = highlights
        record.metricsGeneratedAt = now
        
        let metrics = SpeechMetrics(
            recordID: recordID,
            generatedAt: now,
            wordsPerMinute: wpm,
            fillerCount: fillerTotal,
            fillerWords: fillerDict,
            paceVariability: nil,
            spikeCount: nil
        )

        crashLogger.setValue("runAnalysis_done", forKey: "analysis_phase")
        crashLogger.log("DefaultSpeechAnalysisPipeline: run done transcriptLen=\(cleaned.count) highlights=\(highlights.count)")
        
        return (record, metrics)
    }
}
