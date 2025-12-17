//
//  QualitativeMetrics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import Foundation

struct QualitativeMetrics: Codable, Hashable {
    var delivery: EmojiRating      // 전달력 / 발화 안정감
    var clarity: EmojiRating       // 명료함 / 이해도
    var confidence: EmojiRating    // 자신감 / 에너지
    var structure: EmojiRating     // 답변 구조 / 논리
    
    static let neutral: QualitativeMetrics = .init(
        delivery: .neutral,
        clarity: .neutral,
        confidence: .neutral,
        structure: .neutral
    )
}
