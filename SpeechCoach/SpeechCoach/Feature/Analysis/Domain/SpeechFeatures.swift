//
//  SpeechFeatures.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/11/25.
//

import Foundation

struct SpeechFeatures {
    let duration: TimeInterval
    let wpm: Int
    let fillerCount: Int
    let transcriptLength: Int
    
    var minutes: Double {
        max(duration / 60.0, 0.01)
    }
    
    var fillerPerMinute: Double {
        Double(fillerCount) / minutes
    }
    
    var fillerRatio: Double {
        guard transcriptLength > 0 else { return 0 }
        return Double(fillerCount) / Double(transcriptLength)
    }
}
