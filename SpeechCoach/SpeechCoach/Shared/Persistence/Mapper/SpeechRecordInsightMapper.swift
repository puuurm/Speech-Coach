//
//  SpeechRecordInsightMapper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/27/25.
//

import CoreData
import SpeechCoachAnalysis

enum SpeechRecordInsightMapper {
    static func upsert(
        _ insight: SpeechRecord.Insight?,
        into recordEntity: SpeechRecordEntity,
        in context: NSManagedObjectContext
    ) {
        guard let insight else {
            if let existing = recordEntity.insight {
                context.delete(existing)
                recordEntity.insight = nil
            }
            return
        }
        
        let entity = recordEntity.insight ?? SpeechRecordInsightEntity(context: context)
        entity.oneLiner = insight.oneLiner
        entity.problemSummary = insight.problemSummary
        entity.updatedAt = insight.updatedAt
        entity.generatedAt = Date()
        entity.qualitativeData = CodableStore.encode(insight.qualitative)
        entity.transcriptSegmentsData = CodableStore.encode(insight.transcriptSegments)
        
        entity.record = recordEntity
        recordEntity.insight = entity
    }
    
    static func apply(
        _ insight: SpeechRecord.Insight,
        to entity: SpeechRecordInsightEntity
    ) {
        entity.oneLiner = insight.oneLiner
        entity.problemSummary = insight.problemSummary
        entity.updatedAt = insight.updatedAt
        entity.qualitativeData = CodableStore.encode(insight.qualitative)
        entity.transcriptSegmentsData = CodableStore.encode(insight.transcriptSegments)
    }
    
    static func apply(
        _ metrics: QualitativeMetrics,
        to entity: SpeechRecordInsightEntity
    ) {
        entity.qualitativeData = CodableStore.encode(metrics)
        entity.updatedAt = Date()
    }
    
    static func toDomain(
        _ entity: SpeechRecordInsightEntity?
    ) -> SpeechRecord.Insight? {
        guard let entity else { return nil }
        return SpeechRecord.Insight(
            oneLiner: entity.oneLiner ?? "",
            problemSummary: entity.problemSummary ?? "",
            qualitative: CodableStore.decode(
                QualitativeMetrics.self,
                from: entity.qualitativeData
            ),
            transcriptSegments: CodableStore.decode(
                [TranscriptSegment].self,
                from: entity.transcriptSegmentsData
            ),
            updatedAt: entity.updatedAt ?? .distantPast
        )
    }
}
