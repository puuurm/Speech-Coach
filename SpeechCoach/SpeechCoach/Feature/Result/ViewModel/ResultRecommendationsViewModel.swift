//
//  ResultRecommendationsViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import SwiftUI
import Combine

// MARK: - Recommendation ViewModel

@MainActor
final class ResultRecommendationsViewModel: ObservableObject {

    @Published private(set) var suggestions: [TemplateSuggestion] = []

    struct PaceThresholds {
        var slowWPM: Int = 110
        var fastWPM: Int = 170
        var slowRatioTrigger: Double = 0.35
        var fastRatioTrigger: Double = 0.35
        var variabilityTrigger: Double = 0.25
        var spikeTrigger: Int = 3
    }

    private let thresholds: PaceThresholds

    init(thresholds: PaceThresholds = .init()) {
        self.thresholds = thresholds
    }

    func buildSuggestions(
        recordID: UUID,
        averageWPM: Int,
        speedSeries: SpeedSeries
    ) {
        let signals = Self.makeCoachingSignals(
            recordID: recordID,
            averageWPM: averageWPM,
            speedSeries: speedSeries,
            thresholds: thresholds
        )

        self.suggestions = Self.makeTemplateSuggestions(from: signals)
    }

    // MARK: - CoachingSignals 생성
    
    private static func makeCoachingSignals(
        recordID: UUID,
        averageWPM: Int,
        speedSeries: SpeedSeries,
        thresholds: PaceThresholds
    ) -> CoachingSignals {

        let binWPMs: [Double] = speedSeries.bins.map { bin in
            let seconds = max(1.0, bin.end - bin.start)
            return (Double(bin.wordCount) / seconds) * 60.0
        }

        let binCount = binWPMs.count
        let total = max(1, binCount)

        let sorted = binWPMs.sorted()
        let medianWPM = sorted.isEmpty ? nil : Int(sorted[sorted.count / 2])
        let p10WPM = sorted.isEmpty ? nil : Int(sorted[Int(Double(sorted.count) * 0.1)])
        let p90WPM = sorted.isEmpty ? nil : Int(sorted[Int(Double(sorted.count) * 0.9)])

        let slowCount = binWPMs.filter { $0 < Double(thresholds.slowWPM) }.count
        let fastCount = binWPMs.filter { $0 > Double(thresholds.fastWPM) }.count
        let slowRatio = Double(slowCount) / Double(total)
        let fastRatio = Double(fastCount) / Double(total)

        let variability: Double? = {
            guard binWPMs.count >= 2 else { return nil }
            let mean = binWPMs.reduce(0, +) / Double(binWPMs.count)
            guard mean > 0 else { return nil }
            let variance = binWPMs
                .map { ($0 - mean) * ($0 - mean) }
                .reduce(0, +) / Double(binWPMs.count)
            return sqrt(variance) / mean
        }()

        let spikeCount: Int = {
            guard binWPMs.count >= 2 else { return 0 }
            var spikes = 0
            for i in 1..<binWPMs.count {
                let prev = binWPMs[i - 1]
                let cur = binWPMs[i]
                let base = max(1.0, prev)
                let deltaRatio = abs(cur - prev) / base
                if deltaRatio >= 0.35 {
                    spikes += 1
                }
            }
            return spikes
        }()

        var signals: [CoachingSignal] = []

        let evidence = CoachingSignal.Evidence(
            avgWPM: averageWPM,
            medianWPM: medianWPM,
            p10WPM: p10WPM,
            p90WPM: p90WPM,
            variability: variability,
            spikeCount: spikeCount,
            binSeconds: speedSeries.binSeconds,
            binCount: binCount,
            slowThresholdWPM: thresholds.slowWPM,
            fastThresholdWPM: thresholds.fastWPM,
            spikeDeltaThresholdWPM: Int(0.35 * 100)
        )

        if averageWPM < thresholds.slowWPM {
            signals.append(
                CoachingSignal(
                    recordID: recordID,
                    kind: .paceTooSlowOverall,
                    severity: averageWPM < thresholds.slowWPM - 20 ? .high : .medium,
                    evidence: evidence
                )
            )
        }

        if averageWPM > thresholds.fastWPM {
            signals.append(
                CoachingSignal(
                    recordID: recordID,
                    kind: .paceTooFastOverall,
                    severity: averageWPM > thresholds.fastWPM + 20 ? .high : .medium,
                    evidence: evidence
                )
            )
        }

        if let variability, variability >= thresholds.variabilityTrigger {
            signals.append(
                CoachingSignal(
                    recordID: recordID,
                    kind: .paceUnstable,
                    severity: variability >= thresholds.variabilityTrigger * 1.5 ? .high : .medium,
                    evidence: evidence
                )
            )
        }

        if spikeCount >= thresholds.spikeTrigger {
            signals.append(
                CoachingSignal(
                    recordID: recordID,
                    kind: .paceSpiky,
                    severity: spikeCount >= thresholds.spikeTrigger * 2 ? .high : .medium,
                    evidence: evidence
                )
            )
        }

        return CoachingSignals(
            recordID: recordID,
            generatedAt: Date(),
            signals: signals
        )
    }


    // MARK: - 추천 템플릿 생성 (Signal → UI)

    private static func makeTemplateSuggestions(
        from coachingSignals: CoachingSignals
    ) -> [TemplateSuggestion] {

        var out: [TemplateSuggestion] = []

        for signal in coachingSignals.signals {
            switch signal.kind {

            case .paceTooSlowOverall:
                let avg = signal.evidence.avgWPM ?? 0
                out.append(
                    TemplateSuggestion(
                        title: "속도 조금 올리기",
                        body: "평균 속도(\(avg) WPM)가 다소 느린 편이에요. 문장 끝을 끌지 말고 핵심 단어 위주로 5~10%만 속도를 올려보세요.",
                        category: .improvements,
                        isActionItem: true
                    )
                )

            case .paceTooFastOverall:
                let avg = signal.evidence.avgWPM ?? 0
                out.append(
                    TemplateSuggestion(
                        title: "속도 조금 낮추기",
                        body: "평균 속도(\(avg) WPM)가 빠른 편이에요. 한 문장마다 0.3초 정도 의도적인 쉼을 넣어 전달력을 높여보세요.",
                        category: .improvements,
                        isActionItem: true
                    )
                )

            case .paceUnstable:
                out.append(
                    TemplateSuggestion(
                        title: "속도 균형 잡기",
                        body: "구간별 속도 편차가 커요. 서론–본론–결론을 비슷한 템포로 유지하고, 중요한 문장만 느리게 말해보세요.",
                        category: .nextStep,
                        isActionItem: false
                    )
                )

            case .paceSpiky:
                let spikes = signal.evidence.spikeCount ?? 0
                out.append(
                    TemplateSuggestion(
                        title: "급가속 줄이기",
                        body: "속도가 급격히 변한 구간이 \(spikes)번 있었어요. 전환 구간에서 호흡을 먼저 고정해보세요.",
                        category: .nextStep,
                        isActionItem: true
                    )
                )

            case .paceFlat:
                out.append(
                    TemplateSuggestion(
                        title: "속도에 리듬 주기",
                        body: "속도가 너무 일정해 읽는 느낌이 날 수 있어요. 강조 단어 앞에서만 속도를 살짝 늦춰 리듬을 만들어보세요.",
                        category: .nextStep,
                        isActionItem: false
                    )
                )
            }
        }

        // fallback
        if out.isEmpty {
            out.append(
                TemplateSuggestion(
                    title: "전달력 유지",
                    body: "현재 말하기 속도는 전달에 큰 문제가 없어요. 지금 페이스를 유지하며 내용 명확성에 집중해보세요.",
                    category: .strengths,
                    isActionItem: false
                )
            )
        }

        return out
    }

}
