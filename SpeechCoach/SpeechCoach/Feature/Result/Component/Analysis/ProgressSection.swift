//
//  ProgressSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI

struct ProgressSection: View {
    let current: SpeechMetrics
    let previous: SpeechMetrics
    
    var body: some View {
        Group {
            let wpmDiff = current.wordsPerMinute - previous.wordsPerMinute
            let fillerDiff = current.fillerCount - previous.fillerCount
            
            VStack(alignment: .leading, spacing: 6) {
                Text("이번 영상 vs 이전 영상")
                    .font(.headline)
    
                Text("· 속도: \(previous.wordsPerMinute) → \(current.wordsPerMinute) WPM (\(diffString(wpmDiff)))")
                    .font(.subheadline)
                
                Text("· 군더더기 말: \(previous.fillerCount) → \(current.fillerCount)회 (\(improvementString(forDecreaseOf: fillerDiff)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func diffString(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\(value)" }
        return "변화 없음"
    }
    
    private func improvementString(forDecreaseOf delta: Int) -> String {
        if delta < 0 { return "+\(-delta)" }
        if delta > 0 { return "-\(delta)" }
        return "변화 없음"
    }
}
