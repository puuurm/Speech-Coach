//
//  SpeechTypeSummaryViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel (SpeechMetrics -> SpeechTypeSummary UI)

@MainActor
final class SpeechTypeSummaryViewModel: ObservableObject {
    @Published private(set) var speechType: SpeechTypeSummary?

    private let paceClassifier: PaceClassifier

    init(paceClassifier: PaceClassifier = .init()) {
        self.paceClassifier = paceClassifier
    }

    func load(from metrics: SpeechMetrics) {
        // 1) paceType: 평균 WPM 기반 “느림/적절/빠름”
        let paceType = paceClassifier.paceType(from: metrics.wordsPerMinute)

        // 2) paceStability: 변동성/스파이크 기반 “안정/흔들림”
        let paceStability = paceClassifier.stability(
            variability: metrics.paceVariability,
            spikeCount: metrics.spikeCount
        )

        // 3) 나머지( pause/structure/confidence )는 현재 metrics에 없으니 기본값/placeholder
        //    (추후 SpeechMetrics에 pauseSeries / structureScore 등을 넣으면 여기서 분류)
        let pauseType: PauseType = .thinkingPause
        let structureType: StructureType = .partial
        let confidenceType: ConfidenceType = .neutral

        // 4) oneLiner: UI 요약 문구 (분석탭 “말하기 타입 요약”용)
        let oneLiner = paceClassifier.oneLiner(paceType: paceType, stability: paceStability)

        // 5) highlights: “타입 요약 섹션에서 같이 보여줄” 하이라이트가 있다면 외부에서 주입하는 편이 더 깔끔
        //    (지금 요청 범위에서는 metrics 기반만이라 빈 배열로 둠)
        let highlights: [SpeechHighlight] = []

        self.speechType = SpeechTypeSummary(
            paceType: paceType,
            paceStability: paceStability,
            pauseType: pauseType,
            structureType: structureType,
            confidenceType: confidenceType,
            oneLiner: oneLiner,
            highlights: highlights
        )
    }
}

// MARK: - Classifier (metrics-based rules)

struct PaceClassifier {
    // 앱 내 “적절한 말하기 속도” 기준을 한 곳에서 관리
    var slowWPM: Int = 120
    var fastWPM: Int = 170

    // 안정성 기준(없으면 conservative)
    var variabilityStableMax: Double = 0.18
    var spikeStableMax: Int = 2

    func paceType(from avgWPM: Int) -> PaceType {
        if avgWPM < slowWPM { return .slow }
        if avgWPM > fastWPM { return .fast }
        return .comfortable
    }

    func stability(variability: Double?, spikeCount: Int?) -> StabilityLevel {
        let v = variability ?? 0
        let s = spikeCount ?? 0

        // “둘 중 하나라도 불안정 기준 넘으면” 흔들림으로
        if v > variabilityStableMax || s > spikeStableMax {
            return .unstable
        } else {
            return .stable
        }
    }

    func oneLiner(paceType: PaceType, stability: StabilityLevel) -> String {
        switch (paceType, stability) {
        case (.slow, .stable):
            return "전반적으로 천천히, 속도는 비교적 일정해요."
        case (.slow, .unstable):
            return "전반적으로 천천히, 구간별 속도 흔들림이 있어요."
        case (.comfortable, .stable):
            return "속도는 적절하고, 구간별 페이스도 안정적이에요."
        case (.comfortable, .unstable):
            return "속도는 적절하지만, 구간별 페이스가 흔들릴 수 있어요."
        case (.fast, .stable):
            return "전반적으로 빠르게, 속도는 비교적 일정해요."
        case (.fast, .unstable):
            return "전반적으로 빠르게, 구간별 속도 변화가 커요."
        default:
            return "말하기 속도 특성을 요약했어요."
        }
    }
}


@MainActor
final class ResultMetricsViewModel: ObservableObject {

    // Output for UI
    @Published private(set) var metrics: SpeechMetrics?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let recordID: UUID
    private let repo: SpeechMetricsRepository

    init(recordID: UUID, repo: SpeechMetricsRepository) {
        self.recordID = recordID
        self.repo = repo
    }

    func load() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let m = try await repo.fetch(recordID: recordID)
                self.metrics = m
                self.isLoading = false
            } catch {
                self.metrics = nil
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// ResultScreen에서 카드/섹션을 쉽게 그리기 위한 파생값들
    var wpmText: String {
        guard let m = metrics else { return "—" }
        return "\(m.wordsPerMinute) WPM"
    }

    var fillerText: String {
        guard let m = metrics else { return "—" }
        return "\(m.fillerCount)회"
    }

    var paceVariabilityText: String {
        guard let v = metrics?.paceVariability else { return "—" }
        // 예: 0.23 -> 23%
        return "\(Int((v * 100).rounded()))%"
    }

    var spikeText: String {
        guard let s = metrics?.spikeCount else { return "—" }
        return "\(s)회"
    }

    var topFillerWords: [(word: String, count: Int)] {
        guard let dict = metrics?.fillerWords else { return [] }
        return dict
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
}
