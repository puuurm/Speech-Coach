//
//  CoachingSignal.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import Foundation

struct CoachingSignal: Hashable, Codable, Identifiable {
    enum Kind: String, Codable, Hashable {
        case paceTooSlowOverall
        case paceTooFastOverall
        case paceUnstable
        case paceSpiky
        case paceFlat
    }

    enum Severity: String, Codable, Hashable { case low, medium, high }

    let id: UUID
    let recordID: UUID
    let kind: Kind
    let severity: Severity

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
        var avgWPM: Int?
        var medianWPM: Int?
        var p10WPM: Int?
        var p90WPM: Int?
        var variability: Double?
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
