//
//  DailyHomework.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/20/26.
//

import Foundation

struct DailyHomework: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let drillType: DrillType
    let sourceHighlughtID: UUID
    var isCompleted: Bool
}
	
