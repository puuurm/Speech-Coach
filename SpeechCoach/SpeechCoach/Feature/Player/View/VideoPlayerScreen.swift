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
    
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var recordStore: SpeechRecordStore
    
    private let speechService = RealSpeechService()
    private let analyzer = TranscriptAnalyzer()
    
    @State private var pendingSeek: Double? = nil
    
    @EnvironmentObject private var pc: PlayerController
    
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
    
    private var canProceed: Bool {
        switch mode {
        case .normal:
            return playbackEnded && analyzedRecord != nil
        case .highlightReview:
            return analyzedRecord != nil
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
        .onDisappear {
            pc.player.pause()
        }
        .sheet(isPresented: $showFeedbackSheet, onDismiss: {
            if let second = pendingSeek {
                pc.seek(to: second, autoplay: true)
                pendingSeek = nil
            }
        }) {
            if let record = analyzedRecord {
                NavigationStack {
                    ResultScreen(
                        recordID: record.id,
                        playbackPolicy: .playable { start in
                            pc.seek(to: start, autoplay: true)
                            showFeedbackSheet = false
                        },
                        onRequestPlay: { sec in
                            pendingSeek = sec
                            showFeedbackSheet = false
                        }
                    )
                }
            }
        }
//        .sheet(isPresented: $showFeedbackSheet) {
//            if let record = analyzedRecord {
//                NavigationStack {
//                    ResultScreen(
//                        recordID: record.id,
//                        playbackPolicy: .playable { start in
//                            pc.seek(to: start, autoplay: true)
//                            showFeedbackSheet = false
//                        },
//                        onRequestPlay: { sec in
//                            pc.seek(to: sec, autoplay: autoplay)
//                        }
//                    )
//                }
//            }
//        }
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
                Text("카톡 → 사진 앱에 저장된 영상")
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
                
            case .failed(let message):
                failedView(message: message)
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
                metricBadge(
                    title: "필러",
                    value: fillerCountText(record.summaryFillerCount)
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
                Text(record.transcript)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
            
            Button {
                pc.player.pause()
                showFeedbackSheet = true
            } label: {
                Text("피드백 작성하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canProceed)
            .padding(.top, 4)
        }
    }

    
    func failedView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("분석에 실패했어요")
                .font(.subheadline.weight(.medium))
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
            
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
    
    func metricBadge(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote.weight(.medium))
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
        
        phase = .analyzing
        isStartingAnalysis = true
        
        Task {
            do {
                let (record, metrics) = try await runAnalysis()
                recordStore.upsertBundle(record: record, metrics: metrics)
                
                await MainActor.run {
                    analyzedRecord = record
                    analyzedMetrics = metrics
                    
                    if isEffectivelyEnded(pc.player) {
                        playbackEnded = true
                    }
                    
                    phase = playbackEnded ? .ready : .waitingForPlaybackEnd
                    isStartingAnalysis = false
                }
            } catch {
                await MainActor.run {
                    phase = .failed(error.localizedDescription)
                    isStartingAnalysis = false
                }
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
    
    func retryAnalysis() {
        analyzedRecord = nil
        startPlaybackAndAnalysis()
    }
    
    func runAnalysis() async throws -> (SpeechRecord, SpeechMetrics) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko_RK"))!
        let audioURL = try await speechService.exportAudio(from: videoURL)
        let rawTranscript = try await speechService.transcribe(videoURL: videoURL)
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
        
        let title = SpeechTitleBuilder.makeTitle(
            transcript: cleaned,
            createdAt: Date()
        )
        let recordID = UUID()
        let relative = try VideoStore.shared.importToSandbox(sourceURL: videoURL, recordID: recordID)
        let now = Date()
        
        var record = SpeechRecord(
            id: recordID,
            createdAt: now,
            title: title,
            duration: duration,
            summaryWPM: wpm,
            summaryFillerCount: fillerTotal,
            metricsGeneratedAt: now,
            transcript: cleaned,
            studentName: "희정님",
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

        return (record, metrics)
    }
}
    
