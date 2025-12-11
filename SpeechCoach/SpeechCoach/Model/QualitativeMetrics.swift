//
//  QualitativeMetrics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import Foundation

enum EmojiRating: Int, Codable, CaseIterable {
    case veryBad = 1
    case bad
    case normal
    case good
    case veryGood
}

struct QualitativeMetrics: Codable, Hashable {
    var delivery: EmojiRating       // 전달력
    var fluency: EmojiRating        // 여유/속도감
    var naturalness: EmojiRating    // 표정 자연스러움
    var eyeContact: EmojiRating     // 시선 처리
    var gesture: EmojiRating        // 자세/제스처

    static var neutral: QualitativeMetrics {
        .init(
            delivery: .normal,
            fluency: .normal,
            naturalness: .normal,
            eyeContact: .normal,
            gesture: .normal
        )
    }
}
