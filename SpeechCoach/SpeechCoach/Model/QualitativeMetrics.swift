//
//  QualitativeMetrics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import Foundation

struct QualitativeMetrics: Codable, Hashable {
    var delivery: Int       // 전달력
    var fluency: Int        // 여유/속도감
    var naturalness: Int    // 표정 자연스러움
    var eyeContact: Int     // 시선 처리
    var gesture: Int        // 자세/제스처
    
    static let empty = QualitativeMetrics(
        delivery: 0,
        fluency: 0,
        naturalness: 0,
        eyeContact: 0,
        gesture: 0
    )
}
