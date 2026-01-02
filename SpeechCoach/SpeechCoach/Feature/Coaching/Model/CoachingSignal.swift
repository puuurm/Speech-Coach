//
//  CoachingSignal.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import Foundation

struct CoachingSignal: Hashable, Codable, Identifiable {
    enum Kind: String, Codable, Hashable {
        // 속도 관련
        case paceTooSlowOverall
        case paceTooFastOverall
        case paceUnstable          // 구간별 편차 큼
        case paceSpiky             // 급격한 스파이크 많음
        case paceFlat              // 너무 일정(읽기 느낌) / 필요시

    }

    enum Severity: String, Codable, Hashable { case low, medium, high }

    let id: UUID
    let recordID: UUID
    let kind: Kind
    let severity: Severity

    /// UI가 아닌 "판단 근거"로 남길 필드들 (디버그/설명/로그/AB테스트에 유용)
    let generatedAt: Date
    let evidence: Evidence

    init(recordID: UUID, kind: Kind, severity: Severity, generatedAt: Date = .init(), evidence: Evidence) {
        self.id = UUID()
        self.recordID = recordID
        self.kind = kind
        self.severity = severity
        self.generatedAt = generatedAt
        self.evidence = evidence
    }

    struct Evidence: Hashable, Codable {
        // 핵심 근거 수치(원하면 더 추가)
        var avgWPM: Int?
        var medianWPM: Int?
        var p10WPM: Int?
        var p90WPM: Int?
        var variability: Double?     // CV 같은 값
        var spikeCount: Int?
        var binSeconds: TimeInterval
        var binCount: Int

        var slowThresholdWPM: Int?
        var fastThresholdWPM: Int?
        var spikeDeltaThresholdWPM: Int?
    }
}

struct CoachingSignals: Hashable, Codable {
    let recordID: UUID
    let generatedAt: Date
    let signals: [CoachingSignal]
}
