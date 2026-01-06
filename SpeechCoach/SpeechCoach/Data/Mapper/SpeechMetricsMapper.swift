//
//  SpeechMetricsMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/3/26.
//

import Foundation
import CoreData

enum SpeechMetricsMapper {
    nonisolated static func toDomain(_ entity: SpeechMetricsEntity) -> SpeechMetrics? {
        guard let recordID = entity.record?.id else { return nil }
        let fillerWords: [String: Int] = (entity.fillerWordsData.flatMap { CodableStore.decode([String:Int].self, from: $0) }) ?? [:]
        return SpeechMetrics(
            recordID: recordID,
            generatedAt: entity.generatedAt ?? Date(),
            wordsPerMinute: Int(entity.wordsPerMinute),
            fillerCount: Int(entity.fillerCount),
            fillerWords: fillerWords,
            paceVariability: entity.value(forKey: "paceVariability") as? Double,
            spikeCount: (entity.value(forKey: "spikeCount") as? Int32).map(Int.init)
        )
    }
    
    static func apply(_ metrics: SpeechMetrics, to entity: SpeechMetricsEntity) {
        if entity.id == nil {
            entity.id = UUID()
        }
        entity.generatedAt = metrics.generatedAt
        entity.wordsPerMinute = Int32(metrics.wordsPerMinute)
        entity.fillerCount = Int32(metrics.fillerCount)
        entity.fillerWordsData = CodableStore.encode(metrics.fillerWords)
        entity.setValue(metrics.paceVariability, forKey: "paceVariability")
        entity.setValue(metrics.spikeCount, forKey: "spikeCount")
    }
}
