//
//  VideoPlayerScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import AVKit
import Speech
import SwiftUITooltip

struct VideoPlayerScreen: View {
    @Environment(\.crashLogger) private var crashLogger
    
    let videoURL: URL
    let title: String
    let startTime: TimeInterval?
    let autoplay: Bool
    let mode: VideoPlayerScreenMode
    var tooltipConfig = DefaultTooltipConfig()
    
    init (
        videoURL: URL,
        title: String,
        startTime: TimeInterval? = nil,
        autoplay: Bool = false,
        mode: VideoPlayerScreenMode = .normal
    ) {
        self.videoURL = videoURL
        self.title = title
        self.startTime = startTime
        self.autoplay = autoplay
        self.mode = mode
        
        self.tooltipConfig.enableAnimation = true
        self.tooltipConfig.animationOffset = 10
        self.tooltipConfig.animationTime = 1
    }
    
    @State private var duration: TimeInterval = 0
    @State private var isLoadingDuration = true
    
    @State private var phase: AnalysisPhase = .idle
    @State private var playbackEnded: Bool = false
    
    @State private var isStartingAnalysis: Bool = false
    @State private var tapAnalysisButton: Bool = false

    @State private var analyzedRecord: SpeechRecord?
    @State private var analyzedMetrics: SpeechMetrics?
    @State private var showFeedbackSheet: Bool = false
    
    @State private var appliedStartTime = false
    @State private var tooltipVisible = false
    @State private var pendingSeek: Double? = nil
    @State private var failedToSave = false
    
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var recordStore: SpeechRecordStore
    
    private let speechService = RealSpeechService()
    private let analyzer = TranscriptAnalyzer()
    
    @EnvironmentObject private var pc: PlayerController
    
    @AppStorage("hide_fullflow_banner")
    private var hideFullFlowBanner: Bool = false
    
    @State private var analysisTask: Task<Void, Never>?
    @State private var analysisRunID: UUID?
    
    var allowsAnalysisStart: Bool {
        switch mode {
        case .normal: return true
        case .highlightReview: return false
        }
    }
    
    var showsFeedbackCTA: Bool {
        switch mode {
        case .normal:
            return true
        case .highlightReview(let show):
            return show
        }
    }
    
    private var canOpenFeedback: Bool {
        analyzedRecord != nil
    }
    
    private var shouldShowFullFlowBanner: Bool {
        guard analyzedRecord != nil else { return false }
        guard hideFullFlowBanner == false else { return false }
        switch mode {
        case .normal: return playbackEnded == false
        case .highlightReview: return false
        }
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                VideoPlayer(player: pc.player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(16)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    if pc.isReadyToPlay {
                        infoSection
                        analysisStatusSection
                    } else {
                        loadingVideoView
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .navigationTitle(mode == .normal ? "영상 확인" : "하이라이트 확인")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            crashLogger.setValue("VideoPlayerScreen", forKey: "screen")
            crashLogger.setValue(title, forKey: "video_title")
            clog("appear url=\(videoURL.lastPathComponent) startTime=\(startTime ?? -1) autoplay=\(autoplay) mode=\(mode)")
            
            AudioSessionManager.configureForPlayback()
            pc.load(url: videoURL)

            if duration == 0 {
                isLoadingDuration = true
                Task {
                    let asset = AVAsset(url: videoURL)
                    let seconds = CMTimeGetSeconds(asset.duration)
                    let value = seconds.isFinite ? seconds : 0
                    await MainActor.run {
                        self.duration = value
                        self.isLoadingDuration = false
                    }
                }
            } else {
                isLoadingDuration = false
            }
            
            if let startTime, !appliedStartTime {
                appliedStartTime = true
                clog("apply startTime seek=\(startTime)")
                pc.seek(to: startTime, autoplay: autoplay)
            }
        }
        .onChange(of: pc.didReachEnd) { ended in
            guard ended else { return }
            playbackEnded = true
            
            if case .waitingForPlaybackEnd = phase {
                phase = .ready
            }
        }
        .onChange(of: pc.isPlaying) { playing in
            if !tapAnalysisButton {
                tooltipVisible = true
            }
        }
        .onChange(of: failedToSave) { failed in
            guard failed else { return }
            clog("note save failed (failedToSave=true)")
        }
        .onDisappear {
            clog("disappear -> cancelAnalysis + stopAndTearDown")
            cancelAnalysis()
            pc.stopAndTearDown()
        }
        .sheet(isPresented: $showFeedbackSheet, onDismiss: {
            if let second = pendingSeek {
                pc.seek(to: second, autoplay: true)
                pendingSeek = nil
            }
        }) {
            if let record = analyzedRecord {
                FeedbackResultSheet(
                    recordID: record.id,
                    shouldShowFullFlowBanner: shouldShowFullFlowBanner,
                    onPlaybackStart: { start in
                        pc.seek(to: start, autoplay: true)
                        showFeedbackSheet = false
                    },
                    onRequestPlay: { sec in
                        pendingSeek = sec
                        showFeedbackSheet = false
                    },
                    onTapWatchVideo: {
                        clog("tap: watch video")
                        showFeedbackSheet = false
                        pc.player.play()
                    },
                    onTapDontShowAgain: {
                        hideFullFlowBanner = true
                    },
                    failedToSave: $failedToSave
                )
                .environmentObject(pc)
            }
        }
    }
}

// MARK: - Subviews

private extension VideoPlayerScreen {
    
    var loadingVideoView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("영상 불러오는 중")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(cleanTitle(from: title))
                .font(.headline)
            
            HStack(spacing: 12) {
                Label(durationString(duration), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("사진 앱에 저장된 영상")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var analysisStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch phase {
            case .idle:
                idleStateView
                
            case .analyzing:
                analyzingView
                
            case .waitingForPlaybackEnd:
                waitingForPlaybackEndView
                
            case .ready:
                if let record = analyzedRecord {
                    readyView(record: record)
                } else {
                    // 이론상 거의 안 오는 상태지만 방어 코드
                    Text("분석 결과를 불러오는 중입니다…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
            case .failed(let error):
                failedView(error: error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }
    
    var idleStateView: some View {
        Group {
            switch mode {
            case .normal:
                VStack(alignment: .leading, spacing: 8) {
                    Text("영상 재생부터 시작해볼까요?")
                        .font(.subheadline.weight(.medium))
                    Text("재생 버튼을 누르면, 영상과 동시에 아래에서 스크립트를 분석해둘게요.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button {
                        clog("tap: startPlaybackAndAnalysis")
                        tooltipVisible = false
                        tapAnalysisButton = true
                        startPlaybackAndAnalysis()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("영상 재생 & 분석 시작")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 4)
                    .tooltip(self.tooltipVisible, side: .bottom, config: tooltipConfig) {
                        Text("이 영상으로 말하기 분석을 \n시작할 수 있어요")
                            .padding(5)
                    }
                }
            case .highlightReview:
                VStack(alignment: .leading, spacing: 8) {
                     Text("하이라이트 구간을 확인해보세요.")
                         .font(.subheadline.weight(.medium))
                     Text("이 화면에서는 분석을 다시 돌리지 않고, 재생/구간 이동만 제공합니다.")
                         .font(.footnote)
                         .foregroundColor(.secondary)

                     Button {
                         clog("tap: play (highlightReview)")
                         pc.player.play()
                     } label: {
                         HStack {
                             Image(systemName: "play.fill")
                             Text("재생")
                         }
                         .font(.headline)
                         .frame(maxWidth: .infinity)
                         .padding(.vertical, 12)
                         .background(Color.accentColor)
                         .foregroundColor(.white)
                         .cornerRadius(12)
                     }
                     .padding(.top, 4)
                }
            }
        }
    }
    
    var analyzingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ProgressView()
                Text("영상과 함께 스크립트를 만드는 중입니다…")
                    .font(.subheadline)
            }
            Text("분석이 끝나면 영상이 끝난 뒤 바로 결과가 아래에 나타납니다.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    var waitingForPlaybackEndView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("분석이 완료되었어요.")
                .font(.subheadline.weight(.medium))
        
            Button("결과 보기") {
                phase = .ready
            }
            .buttonStyle(PrimaryFullWidthButtonStyle(cornerRadius: 12))
            
            Text("영상이 끝나면 자동으로 결과 화면이 열려요.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    func readyView(record: SpeechRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("분석 결과")
                .font(.headline)
            
            HStack(spacing: 12) {
                metricBadge(
                    title: "길이",
                    value: durationString(record.duration)
                )
                metricBadge(
                    title: "속도",
                    value: wpmText(record.summaryWPM)
                )
            }
            
            if record.highlights.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text("체크할 구간")
                        .font(.subheadline.weight(.semibold))
                    
                    ForEach(record.highlights.prefix(3)) { h in
                        SpeechHighlightRow(
                            item: h,
                            duration: record.duration,
                            context: .videoReview,
                            playbackPolicy: .playable { start in
                                pc.fallbackDuration = record.duration
                                pc.seek(to: start, autoplay: true)
                            }
                        )
                    }
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("전체 스크립트 (요약)")
                    .font(.subheadline.weight(.medium))
                let hide = TranscriptQualityChecker.shouldHide(transcript: record.transcript, segments: record.insight?.transcriptSegments ?? [])
                
                if hide {
                    Text("주변 소음이 많아 텍스트 변환 정확도가 낮아요.\n조용한 환경에서 다시 녹음해 주세요.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(record.transcript)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
            
            Button {
                pc.player.pause()
                showFeedbackSheet = true
            } label: {
                Text("분석 결과 보기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canOpenFeedback)
            .padding(.top, 4)
        }
    }
    
    private func shouldHideTranscript(
        transcript: String,
        segments: [TranscriptSegment]
    ) -> Bool {
        let t = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return true }

        let count = segments.count
        guard count > 0 else { return true }

        let spokenTime = segments.map(\.duration).reduce(0, +)

        let recognizedSpan: TimeInterval = {
            guard let first = segments.min(by: { $0.startTime < $1.startTime }) else { return 0 }
            let end = segments.map(\.endTime).max() ?? 0
            return max(0, end - first.startTime)
        }()

        let avg = spokenTime / Double(count)
        let density = recognizedSpan > 0 ? Double(count) / recognizedSpan : 0

        if count <= 8 { return true }
        if avg >= 1.2 { return true }
        if density <= 0.4 { return true }

        return false
    }

    
    func failedView(error: UserFacingError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(error.title)
                .font(.subheadline.weight(.medium))
            
            Text(error.message)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            if let suggestion = error.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button {
                retryAnalysis()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도하기")
                }
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
    
    func metricBadge(title: String, value: String, systemImage: String? = nil) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            if let systemImage {
                HStack(spacing: 4) {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.medium))
                    Text(value)
                        .font(.footnote.weight(.medium))
                }
            } else {
                Text(value)
                    .font(.footnote.weight(.medium))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Player & Analysis Logic

private extension VideoPlayerScreen {
    
    func startPlaybackAndAnalysis() {
    
        if isEffectivelyEnded(pc.player) {
            playbackEnded = true
        }
        
        if !playbackEnded {
            pc.player.play()
        }
        
        guard !isStartingAnalysis else { return }
        guard analyzedRecord == nil else { return }
        
        self.analysisTask?.cancel()
        self.analysisTask = nil
        
        phase = .analyzing
        isStartingAnalysis = true
        
        let runID = UUID()
        analysisRunID = runID
        
        crashLogger.setValue(runID.uuidString, forKey: "analysis_run_id")
        crashLogger.setValue("start", forKey: "analysis_phase")
        clog("analysis start runID=\(runID) playbackEnded=\(playbackEnded)")
        
        analysisTask = Task {
            do {
                try Task.checkCancellation()
                
                let (record, metrics) = try await runAnalysis()
                
                try Task.checkCancellation()
                
                recordStore.upsertBundle(record: record, metrics: metrics)
                
                try Task.checkCancellation()
                
                await MainActor.run {
                    guard self.analysisRunID == runID else { return }
                    
                    analyzedRecord = record
                    analyzedMetrics = metrics
                    
                    if isEffectivelyEnded(pc.player) {
                        playbackEnded = true
                    }
                    
                    crashLogger.setValue("done", forKey: "analysis_phase")
                    clog("analysis done runID=\(runID) highlights=\(record.highlights.count) transcriptLen=\(record.transcript.count)")
                    
                    phase = playbackEnded ? .ready : .waitingForPlaybackEnd
                    isStartingAnalysis = false
                    analysisTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.analysisRunID == runID else { return }
                    crashLogger.setValue("cancelled", forKey: "analysis_phase")
                    clog("analysis cancelled runID=\(runID)")
                    isStartingAnalysis = false
                    analysisTask = nil
                }
            } catch {
                crashLogger.setValue("failed", forKey: "analysis_phase")
                crashLogger.record(error)
                clog("analysis failed runID=\(runID) error=\(String(describing: error))")

                await MainActor.run {
                    guard analysisRunID == runID else { return }
                    let userError = mapErrorToUserFacing(error)
                    phase = .failed(userError)
                    isStartingAnalysis = false
                    analysisTask = nil
                }
            }
        }
    }
    
    func mapErrorToUserFacing(_ error: Error) -> UserFacingError {
        let ns = error as NSError

        if ns.domain == "com.apple.coreaudio.avfaudio" {
            return UserFacingError(
                title: "분석을 완료하지 못했어요",
                message: "영상의 오디오를 처리하는 중 문제가 발생했어요.",
                suggestion: "앱을 다시 실행하거나 다른 영상으로 다시 시도해 주세요."
            )
        }

        return UserFacingError(
            title: "분석을 완료하지 못했어요",
            message: "일시적인 오류가 발생했어요.",
            suggestion: "잠시 후 다시 시도해 주세요."
        )
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
    
    func retryAnalysis() {
        analyzedRecord = nil
        startPlaybackAndAnalysis()
    }
    
    func runAnalysis() async throws -> (SpeechRecord, SpeechMetrics) {
        crashLogger.setValue("runAnalysis_start", forKey: "analysis_phase")
        clog("runAnalysis start")

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))!
        let audioURL = try await speechService.exportAudio(from: videoURL)
        
        crashLogger.setValue("transcribe", forKey: "analysis_phase")
        let rawTranscript = try await speechService.transcribe(videoURL: videoURL)
        
        crashLogger.setValue("recognizeDetailed", forKey: "analysis_phase")
        let transcriptResult = try await speechService.recognizeDetailed(url: audioURL, with: recognizer)
        
        let cleaned = transcriptResult.cleanedText
        let segments = transcriptResult.segments
        
        let duration: TimeInterval = {
            if self.duration > 0 {
                return self.duration
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
        let highlights = SpeechHighlightBuilder
            .makeHighlights(
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
        clog("runAnalysis done transcriptLen=\(cleaned.count) highlights=\(highlights.count)")

        return (record, metrics)
    }
    
    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        
        isStartingAnalysis = false
        
        speechService.cancelRecognitionIfSupported()
    }
    
    func mapErrorToUserMessage(_ error: Error) -> UserFacingError {
        let ns = error as NSError

        if ns.domain == "com.apple.coreaudio.avfaudio" {
            return .init(
                title: "분석을 완료하지 못했어요",
                message: "영상의 오디오를 처리하는 중 문제가 발생했어요.",
                suggestion: "앱을 다시 실행하거나 다른 영상으로 다시 시도해 주세요."
            )
        }

        return .init(
            title: "분석을 완료하지 못했어요",
            message: "일시적인 오류가 발생했어요.",
            suggestion: "잠시 후 다시 시도해 주세요."
        )
    }
    
    private func clog(_ message: String) {
        crashLogger.log("VideoPlayerScreen: \(message)")
    }

}
    
