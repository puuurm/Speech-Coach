//
//  VideoAnalysisController.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/27/26.
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class VideoAnalysisController: ObservableObject {
    
    @Published private(set) var phase: AnalysisPhase = .idle
    @Published private(set) var analyzedRecord: SpeechRecord?
    @Published private(set) var analyzedMetrics: SpeechMetrics?
    @Published private(set) var playbackEnded: Bool = false
    
    private var analysisTask: Task<Void, Never>?
    private var analysisRunID: UUID?
    
    private let videoURL: URL
    private let durationProvider: @MainActor () -> TimeInterval
    private unowned let pc: PlayerController
    
    private let recordStore: SpeechRecordStore
    private let pipeline: SpeechAnalysisPipeline
    private let crashLogger: CrashLogging
    private let mapErrorToUserFacing: (Error) -> UserFacingError
    
    init(
        videoURL: URL,
        pc: PlayerController,
        recordStore: SpeechRecordStore,
        pipeline: SpeechAnalysisPipeline,
        crashLogger: CrashLogging,
        durationProvider: @escaping @MainActor () -> TimeInterval,
        mapErrorToUserFacing: @escaping (Error) -> UserFacingError
    ) {
        self.videoURL = videoURL
        self.pc = pc
        self.recordStore = recordStore
        self.pipeline = pipeline
        self.crashLogger = crashLogger
        self.durationProvider = durationProvider
        self.mapErrorToUserFacing = mapErrorToUserFacing
    }
    
    func startPlaybackAndAnalysisIfNeeded() {
        if isEffectivelyEnded(pc.player) {
            playbackEnded = true
        }
        
        if !playbackEnded {
            pc.player.play()
        }
        
        guard analyzedRecord == nil else { return }
        
        if case .analyzing = phase { return }
        
        transition(.startTapped)
        startAnalysisTask()
    }
    
    func retryAnalysis() {
        transition(.reset)
        startPlaybackAndAnalysisIfNeeded()
    }
    
    func cancel() {
        analysisTask?.cancel()
        analysisTask = nil
        
        crashLogger.setValue("cancelled", forKey: "analysis_phase")
        crashLogger.log("VideoAnalysisController: cancelled")
        transition(.cancelled)
    }
    
    func notifyPlaybackEnded() {
        playbackEnded = true
        transition(.playbackEnded)
    }
    
    func openResultNow() {
        transition(.openResultNow)
    }
    
    private func transition(_ event: AnalysisEvent) {
        switch (phase, event) {
        case (.idle, .startTapped):
            phase = .analyzing
            
        case (.analyzing, .analysisSucceeded(let ended, let record, let metrics)):
            analyzedRecord = record
            analyzedMetrics = metrics
            phase = ended ? .ready : .waitingForPlaybackEnd
            
        case (.waitingForPlaybackEnd, .playbackEnded),
            (.waitingForPlaybackEnd, .openResultNow):
            phase = .ready
            
        case (_, .failed(let err)):
            phase = .failed(err)
            
        case (_, .cancelled):
            phase = .idle
            
        case (_, .reset):
            analyzedRecord = nil
            analyzedMetrics = nil
            playbackEnded = false
            phase = .idle
            
        default:
            break
        }
    }
    private func startAnalysisTask() {
        analysisTask?.cancel()
        analysisTask = nil
                
        let runID = UUID()
        analysisRunID = runID
        
        crashLogger.setValue(runID.uuidString, forKey: "analysis_run_id")
        crashLogger.setValue("start", forKey: "analysis_phase")
        crashLogger.log("VideoAnalysisController: analysis start runID=\(runID) playbackEnded=\(playbackEnded)")

        analysisTask = Task {
            do {
                try Task.checkCancellation()
                
                let durationHint = await durationProvider()
                let (record, metrics) = try await pipeline.run(
                    videoURL: videoURL,
                    durationHint: durationHint
                )
                
                try Task.checkCancellation()
                
                recordStore.upsertBundle(record: record, metrics: metrics)
                
                try Task.checkCancellation()
                
                if isEffectivelyEnded(pc.player) {
                    playbackEnded = true
                }
                
                guard self.analysisRunID == runID else { return }
                
                crashLogger.setValue("done", forKey: "analysis_phase")
                crashLogger.log("VideoAnalysisController: analysis done runID=\(runID) highlights=\(record.highlights.count) transcriptLen=\(record.transcript.count)")
                
                analysisTask = nil
                transition(.analysisSucceeded(playbackEnded: playbackEnded, record: record, metrics: metrics))

            } catch is CancellationError {
                guard self.analysisRunID == runID else { return }
                crashLogger.setValue("cancelled", forKey: "analysis_phase")
                crashLogger.log("VideoAnalysisController: analysis cancelled runID=\(runID)")
                analysisTask = nil
                transition(.cancelled)
            } catch {
                crashLogger.setValue("failed", forKey: "analysis_phase")
                crashLogger.record(error)
                crashLogger.log("VideoAnalysisController: analysis failed runID=\(runID) error=\(String(describing: error))")

                guard analysisRunID == runID else { return }
                let userError = mapErrorToUserFacing(error)
                analysisTask = nil
                transition(.failed(userError))
            }
        }
    }
    
    private func isEffectivelyEnded(
        _ player: AVPlayer,
        epsilon: Double = 0.3
    ) -> Bool {
        guard let item = player.currentItem,
              item.duration.isNumeric else {
            return false
        }
        return player.currentTime().seconds >= max(0, item.duration.seconds - epsilon)
    }
}
