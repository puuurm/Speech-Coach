//
//  SpeedCoachingSignalGenerator.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import Foundation

struct SpeedCoachingSignalGenerator {

    struct Config {
        var slowWPM: Int = 120
        var fastWPM: Int = 180
        var variabilityCVThreshold: Double = 0.25
        var spikeDeltaWPM: Int = 40
        var spikeCountThreshold: Int = 3
    }

    static func makeSignals(
        recordID: UUID,
        speedSeries: SpeedSeries,
        config: Config = .init(),
        generatedAt: Date = .init()
    ) -> CoachingSignals {

        let wpmSeries = speedSeries.bins.map { bin -> Int in
            let minutes = max(0.0001, speedSeries.binSeconds / 60.0)
            return Int(round(Double(bin.wordCount) / minutes))
        }

        guard wpmSeries.count >= 2 else {
            return CoachingSignals(recordID: recordID, generatedAt: generatedAt, signals: [])
        }

        let stats = WPMStats.from(wpmSeries)

        var out: [CoachingSignal] = []

        if let avg = stats.avg {
            if avg < config.slowWPM {
                out.append(.init(
                    recordID: recordID,
                    kind: .paceTooSlowOverall,
                    severity: severityByDistance(value: avg, threshold: config.slowWPM, direction: .below),
                    generatedAt: generatedAt,
                    evidence: .init(
                        avgWPM: avg, medianWPM: stats.median, p10WPM: stats.p10, p90WPM: stats.p90,
                        variability: stats.cv, spikeCount: nil,
                        binSeconds: speedSeries.binSeconds, binCount: wpmSeries.count,
                        slowThresholdWPM: config.slowWPM, fastThresholdWPM: config.fastWPM,
                        spikeDeltaThresholdWPM: config.spikeDeltaWPM
                    )
                ))
            } else if avg > config.fastWPM {
                out.append(.init(
                    recordID: recordID,
                    kind: .paceTooFastOverall,
                    severity: severityByDistance(value: avg, threshold: config.fastWPM, direction: .above),
                    generatedAt: generatedAt,
                    evidence: .init(
                        avgWPM: avg, medianWPM: stats.median, p10WPM: stats.p10, p90WPM: stats.p90,
                        variability: stats.cv, spikeCount: nil,
                        binSeconds: speedSeries.binSeconds, binCount: wpmSeries.count,
                        slowThresholdWPM: config.slowWPM, fastThresholdWPM: config.fastWPM,
                        spikeDeltaThresholdWPM: config.spikeDeltaWPM
                    )
                ))
            }
        }

        if let cv = stats.cv, cv >= config.variabilityCVThreshold {
            out.append(.init(
                recordID: recordID,
                kind: .paceUnstable,
                severity: cv >= config.variabilityCVThreshold * 1.5 ? .high : .medium,
                generatedAt: generatedAt,
                evidence: .init(
                    avgWPM: stats.avg, medianWPM: stats.median, p10WPM: stats.p10, p90WPM: stats.p90,
                    variability: cv, spikeCount: nil,
                    binSeconds: speedSeries.binSeconds, binCount: wpmSeries.count,
                    slowThresholdWPM: config.slowWPM, fastThresholdWPM: config.fastWPM,
                    spikeDeltaThresholdWPM: config.spikeDeltaWPM
                )
            ))
        }

        let spikeCount = countSpikes(wpmSeries, deltaThreshold: config.spikeDeltaWPM)
        if spikeCount >= config.spikeCountThreshold {
            out.append(.init(
                recordID: recordID,
                kind: .paceSpiky,
                severity: spikeCount >= config.spikeCountThreshold * 2 ? .high : .medium,
                generatedAt: generatedAt,
                evidence: .init(
                    avgWPM: stats.avg, medianWPM: stats.median, p10WPM: stats.p10, p90WPM: stats.p90,
                    variability: stats.cv, spikeCount: spikeCount,
                    binSeconds: speedSeries.binSeconds, binCount: wpmSeries.count,
                    slowThresholdWPM: config.slowWPM, fastThresholdWPM: config.fastWPM,
                    spikeDeltaThresholdWPM: config.spikeDeltaWPM
                )
            ))
        }

        return CoachingSignals(recordID: recordID, generatedAt: generatedAt, signals: out)
    }

    // MARK: - helpers

    private enum Direction { case below, above }

    private static func severityByDistance(value: Int, threshold: Int, direction: Direction) -> CoachingSignal.Severity {
        let diff: Int
        switch direction {
        case .below: diff = threshold - value
        case .above: diff = value - threshold
        }
        if diff >= 40 { return .high }
        if diff >= 20 { return .medium }
        return .low
    }

    private static func countSpikes(_ series: [Int], deltaThreshold: Int) -> Int {
        guard series.count >= 2 else { return 0 }
        var count = 0
        for i in 1..<series.count {
            if abs(series[i] - series[i - 1]) >= deltaThreshold {
                count += 1
            }
        }
        return count
    }
}

private struct WPMStats {
    let avg: Int?
    let median: Int?
    let p10: Int?
    let p90: Int?
    let cv: Double?

    static func from(_ series: [Int]) -> WPMStats {
        let clean = series.filter { $0 > 0 }
        guard clean.isEmpty == false else { return .init(avg: nil, median: nil, p10: nil, p90: nil, cv: nil) }

        let avgD = Double(clean.reduce(0, +)) / Double(clean.count)
        let avg = Int(round(avgD))

        let sorted = clean.sorted()
        func percentile(_ p: Double) -> Int {
            let idx = Int(round(p * Double(sorted.count - 1)))
            return sorted[max(0, min(sorted.count - 1, idx))]
        }

        let median = percentile(0.5)
        let p10 = percentile(0.10)
        let p90 = percentile(0.90)

        let variance = clean.reduce(0.0) { $0 + pow(Double($1) - avgD, 2) } / Double(clean.count)
        let std = sqrt(variance)
        let cv = avgD > 0 ? (std / avgD) : nil

        return .init(avg: avg, median: median, p10: p10, p90: p90, cv: cv)
    }
}
