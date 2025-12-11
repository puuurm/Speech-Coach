//
//  QualitativeMetrics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import Foundation

struct QualitativeMetrics: Codable, Hashable {
    var delivery: Int      // 전달력 (1~5)
    var pacing: Int        // 여유/속도감
    var expression: Int    // 표정 자연스러움
    var eyeContact: Int    // 시선 처리
    var posture: Int       // 자세/제스처
}
