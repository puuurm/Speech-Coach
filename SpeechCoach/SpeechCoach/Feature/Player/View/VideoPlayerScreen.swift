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
import SpeechCoachAnalysis

struct VideoPlayerScreen: View {
    @Environment(\.crashLogger) private var crashLogger
    
    let videoURL: URL
    let title: String
    let startTime: TimeInterval?
    let autoplay: Bool
    let mode: VideoPlayerScreenMode
    var tooltipConfig = DefaultTooltipConfig()
    
    @State private var duration: TimeInterval = 0
    @State private var isLoadingDuration = true
    
    @State private var tapAnalysisButton: Bool = false
    @State private var showFeedbackSheet: Bool = false
    
    @State private var appliedStartTime = false
    @State private var tooltipVisible = false
    @State private var pendingSeek: Double? = nil
    @State private var failedToSave = false
    
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var recordStore: SpeechRecordStore
    
    private let speechService = RealSpeechService()
    private let analyzer = TranscriptAnalyzer()
    private var pipeline: SpeechAnalysisPipeline {
        DefaultSpeechAnalysisPipeline(
            speechService: speechService,
            analyzer: analyzer,
            crashLogger: crashLogger
        )
    }
    
    @State private var analysisController: VideoAnalysisController? = nil
    @EnvironmentObject private var pc: PlayerController
    
    @AppStorage("hide_fullflow_banner")
    private var hideFullFlowBanner: Bool = false
    
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
                        if let controller = analysisController {
                            VideoAnalysisStatusSection(
                                controller: controller,
                                mode: mode,
                                pc: pc,
                                tooltipConfig: tooltipConfig,
                                tapAnalysisButton: $tapAnalysisButton,
                                tooltipVisible: $tooltipVisible,
                                showFeedbackSheet: $showFeedbackSheet,
                                pendingSeek: $pendingSeek,
                                hideFullFlowBanner: $hideFullFlowBanner,
                                failedToSave: $failedToSave
                            )
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
            
            if analysisController == nil {
                analysisController = VideoAnalysisController(
                    videoURL: videoURL,
                    pc: pc,
                    persister: recordStore,
                    pipeline: pipeline,
                    crashLogger: crashLogger,
                    durationProvider: { duration },
                    mapErrorToUserFacing: mapErrorToUserFacing
                )
            }
        }
        .onChange(of: pc.didReachEnd) { ended in
            guard ended else { return }
            analysisController?.notifyPlaybackEnded()
        }
        .onChange(of: pc.isPlaying) { playing in
            clog("disappear -> cancelAnalysis + stopAndTearDown")
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
            analysisController?.cancel()
            pc.stopAndTearDown()
        }
        .sheet(isPresented: $showFeedbackSheet, onDismiss: {
            if let second = pendingSeek {
                pc.seek(to: second, autoplay: true)
                pendingSeek = nil
            }
        }) {
            if let record = analysisController?.analyzedRecord {
                FeedbackResultSheet(
                    recordID: record.id,
                    shouldShowFullFlowBanner: {
                        guard analysisController?.analyzedRecord != nil else { return false }
                        guard hideFullFlowBanner == false else { return false }
                        switch mode {
                        case .normal:
                            return (analysisController?.playbackEnded ?? false) == false
                        case .highlightReview:
                            return false
                        }
                    }(),
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
}

// MARK: - Player & Analysis Logic

private extension VideoPlayerScreen {
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
    
    private func clog(_ message: String) {
        crashLogger.log("VideoPlayerScreen: \(message)")
    }

}
    
