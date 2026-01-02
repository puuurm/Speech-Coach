//
//  SpeechMetrics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

// Analysis/Metrics/SpeechMetrics.swift
import Foundation

struct SpeechMetrics: Hashable, Codable {
    let recordID: UUID
    let generatedAt: Date
    let wordsPerMinute: Int
    let fillerCount: Int
    let fillerWords: [String: Int]
    let paceVariability: Double?
    let spikeCount: Int?
}

protocol SpeechMetricsRepository {
    /// recordID에 해당하는 Metrics 1개를 반환 (없으면 nil)
    func fetch(recordID: UUID) async throws -> SpeechMetrics?

    /// 저장(Upsert). 같은 recordID면 최신값으로 교체
    func upsert(_ metrics: SpeechMetrics) async throws

    /// 삭제
    func delete(recordID: UUID) async throws
}

actor InMemorySpeechMetricsRepository: SpeechMetricsRepository {
    private var store: [UUID: SpeechMetrics] = [:]

    func fetch(recordID: UUID) async throws -> SpeechMetrics? {
        store[recordID]
    }

    func upsert(_ metrics: SpeechMetrics) async throws {
        store[metrics.recordID] = metrics
    }

    func delete(recordID: UUID) async throws {
        store.removeValue(forKey: recordID)
    }
}
