//
//  VideoPlayerScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import AVKit
import Speech

struct VideoPlayerScreen: View {
    let draft: SpeechDraft
    
    @State private var player: AVPlayer?
    @State private var duration: TimeInterval = 0
    @State private var isLoadingDuration = true
    
    @State private var phase: AnalysisPhase = .idle
    @State private var playbackEnded: Bool = false
    
    @State private var isStartingAnalysis: Bool = false   // 중복 요청 방지용
    @State private var analyzedRecord: SpeechRecord?      // 분석 결과
    @State private var showFeedbackSheet: Bool = false
    @State private var seekObserver: NSObjectProtocol?
    
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var recordStore: SpeechRecordStore
    
    private let speechService = RealSpeechService()
    private let analyzer = TranscriptAnalyzer()
    
    @StateObject private var seekBridge = HighlightSeekBridge.shared
    
    private var canProceed: Bool {
        playbackEnded && analyzedRecord != nil
    }
    
    init(draft: SpeechDraft) {
        self.draft = draft
        _player = State(initialValue: AVPlayer(url: draft.videoURL))
    }
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(16)
            ScrollView {
                VStack(spacing: 16) {
                    if let player {
                        infoSection
                        analysisStatusSection
                        
    //                    Spacer()
                    } else {
                        loadingVideoView
                    }
                }
            }
        }


        .padding(.horizontal, 20)
        .navigationTitle("영상 확인")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AudioSessionManager.configureForPlayback()
            setupPlayerIfNeeded()
            observePlaybackEnd()
            
            if duration == 0 {
                isLoadingDuration = true
                Task {
                    let asset = AVAsset(url: draft.videoURL)
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
        }
        .onAppear {
            if player == nil {
                player = AVPlayer(url: draft.videoURL)
            }
            
//            if seekObserver == nil, let player {
//                seekObserver = player.observeHighlightSeek()
//            }
        }
        .onReceive(seekBridge.$request) { req in
            guard let req, let player else { return }
            player.seek(to: CMTime(seconds: req.seconds, preferredTimescale: 600))
            if req.autoplay { player.play() }
            seekBridge.consume()
        }
        .onDisappear {
            removePlaybackObserver()
            if let seekObserver {
                NotificationCenter.default.removeObserver(seekObserver)
                self.seekObserver = nil
            }
        }
        .sheet(isPresented: $showFeedbackSheet) {
            if let record = analyzedRecord, let player {
                NavigationStack {
                    ResultScreen(record: record, player: player)
                }
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
            Text(cleanTitle(from: draft.title))
                .font(.headline)
            
            HStack(spacing: 12) {
                Label(durationString(draft.duration), systemImage: "clock")
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
    
    /// 영상 아래에 나오는 분석 상태 / 결과 / 피드백 버튼
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
        VStack(alignment: .leading, spacing: 8) {
            Text("영상 재생부터 시작해볼까요?")
                .font(.subheadline.weight(.medium))
            Text("재생 버튼을 누르면, 영상과 동시에 아래에서 스크립트를 분석해둘게요.")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Button {
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
            Text("영상이 끝나면 바로 아래에서 결과를 보여드릴게요.")
                .font(.footnote)
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
                    value: "\(record.wordsPerMinute) wpm"
                )
                metricBadge(
                    title: "필러",
                    value: "\(record.fillerCount)회"
                )
            }
            
            let speechType = SpeechTypeSummarizer.summarize(
                duration: record.duration,
                wordsPerMinute: record.wordsPerMinute,
                segments: record.transcriptSegments ?? []   // nil이면 빈 배열 -> 하이라이트 없음
            )

            if speechType.highlights.isEmpty == false, let player {
                VStack(alignment: .leading, spacing: 8) {
                    Text("체크할 구간")
                        .font(.subheadline.weight(.semibold))

                    ForEach(speechType.highlights.prefix(3)) { h in
                        SpeechHighlightRow(item: h, duration: record.duration) {
                            player.seek(to: CMTime(seconds: h.start, preferredTimescale: 600))
                            player.play()
                        }
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
            
            Button {
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
    
    func setupPlayerIfNeeded() {
        if player == nil {
            player = AVPlayer(url: draft.videoURL)
        }
    }
    
    func startPlaybackAndAnalysis() {
        guard let player else { return }
        
        // 재생 시작
        player.play()
        playbackEnded = false
        
        // 분석 중복 시작 방지
        guard isStartingAnalysis == false,
              analyzedRecord == nil else {
            phase = .analyzing
            return
        }
        
        phase = .analyzing
        isStartingAnalysis = true
        
        Task {
            do {
                let record = try await runAnalysis()
                
                await MainActor.run {
                    // Store에 저장
                    recordStore.add(record)
//                    router.push(.result(record))
                    
                    analyzedRecord = record
                    
                    if playbackEnded {
                        phase = .ready
                    } else {
                        phase = .waitingForPlaybackEnd
                    }
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
    
    func retryAnalysis() {
        analyzedRecord = nil
        startPlaybackAndAnalysis()
    }
    
    func runAnalysis() async throws -> SpeechRecord {
        // 1) 전사
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko_RK"))!
        let audioURL = try await speechService.exportAudio(from: draft.videoURL)
        let rawTranscript = try await speechService.transcribe(videoURL: draft.videoURL)
        let transcriptResult = try await speechService.recognizeDetailed(url: audioURL, with: recognizer)
        
        // 2) 클린업
        let cleaned = transcriptResult.cleanedText
        
        let segments = transcriptResult.segments
        
        // 3) duration 확보 (draft.duration이 0이면 AVAsset으로 보정)
        let duration: TimeInterval = {
            if draft.duration > 0 {
                return draft.duration
            } else {
                let asset = AVAsset(url: draft.videoURL)
                let seconds = CMTimeGetSeconds(asset.duration)
                return seconds.isFinite ? seconds : 0
            }
        }()
        
        // 4) 분석 지표
        let wpm = analyzer.wordsPerMinute(transcript: cleaned, duration: duration)
        let fillerDict = analyzer.fillerWordsDict(from: cleaned)
        let fillerTotal = fillerDict.values.reduce(0, +)
        
        // 5) 제목 생성 (있다면)
        let title = SpeechTitleBuilder.makeTitle(
            transcript: cleaned,
            createdAt: Date()
        )
        
        // 6) SpeechRecord 생성
        let record = SpeechRecord(
            id: draft.id,
            createdAt: Date(),
            title: title,
            duration: duration,
            wordsPerMinute: wpm,
            fillerCount: fillerTotal,
            transcript: cleaned,
            videoURL: draft.videoURL,
            fillerWords: fillerDict,
            studentName: "희정님",
            noteIntro: "",
            noteStrengths: "",
            noteImprovements: "",
            noteNextStep: "",
            transcriptSegments: segments
        )
        
        return record
    }
    
    func observePlaybackEnd() {
        guard let playerItem = player?.currentItem else { return }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playbackEnded = true
            if case .waitingForPlaybackEnd = phase {
                phase = .ready
            }
        }
    }
    
    func removePlaybackObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
}
    

#Preview {
    VideoPlayerScreen(
        draft: .init(
            id: UUID(),
            title: "예시 발표 영상",
            duration: 120,
            videoURL: URL(fileURLWithPath: "/dev/null")
        )
    )
}
