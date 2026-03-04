//
//  VideoAnalysisStatusSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/4/26.
//

import SwiftUI
import SwiftUITooltip
import SpeechCoachAnalysis
import AVFoundation

struct VideoAnalysisStatusSection: View {
    @ObservedObject var controller: VideoAnalysisController

    let mode: VideoPlayerScreenMode
    let pc: PlayerController
    var tooltipConfig: DefaultTooltipConfig

    @Binding var tapAnalysisButton: Bool
    @Binding var tooltipVisible: Bool
    @Binding var showFeedbackSheet: Bool
    @Binding var pendingSeek: Double?
    @Binding var hideFullFlowBanner: Bool
    @Binding var failedToSave: Bool

    private var canOpenFeedback: Bool {
        controller.analyzedRecord != nil
    }

    private var shouldShowFullFlowBanner: Bool {
        guard controller.analyzedRecord != nil else { return false }
        guard hideFullFlowBanner == false else { return false }

        switch mode {
        case .normal:
            return controller.playbackEnded == false
        case .highlightReview:
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch controller.phase {
            case .idle:
                idleStateView

            case .analyzing:
                analyzingView

            case .waitingForPlaybackEnd:
                waitingForPlaybackEndView

            case .ready:
                if let record = controller.analyzedRecord {
                    readyView(record: record)
                } else {
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
}

extension VideoAnalysisStatusSection {
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
                        controller.startPlaybackAndAnalysisIfNeeded()
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
                controller.openResultNow()
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
                controller.retryAnalysis()
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
