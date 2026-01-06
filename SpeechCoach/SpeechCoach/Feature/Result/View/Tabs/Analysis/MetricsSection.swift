//
//  MetricsSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/6/26.
//

import SwiftUI

struct MetricsSection: View {
    let metrics: SpeechMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("말하기 지표")
                .font(.headline)
            
            VStack(spacing: 12) {
                metricCard(
                    title: "말하기 속도",
                    value: "\(metrics.wordsPerMinute) WPM",
                    detail: wpmComment
                )
                
                metricCard(
                    title: "필러 단어",
                    value: "\(metrics.fillerCount)회",
                    detail: fillerComment
                )
            }
        }
    }
    
    private func metricCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

extension MetricsSection {
    private var wpmComment: String {
        let wpm = metrics.wordsPerMinute
        switch wpm {
        case 0:
            return "속도 정보가 없어요."
        case ..<110:
            return "조금 느린 편이에요. 말 사이 간격을 조금만 줄이면 전달력이 좋아질 것 같아요."
        case 110...160:
            return "듣기 편한 속도에요. 이 속도를 기준으로 유지해보면 좋아요."
        default:
            return "조금 빠른 편이에요. 중요한 문장에서 한 박자 쉬어가는 연습을 해보면 좋아요."
        }
    }
    
    private var fillerComment: String {
        let count = metrics.fillerCount
        switch count {
        case 0:
            return "필러가 거의 없어서 아주 또렷하게 들려요."
        case 1...3:
            return "자연스러운 범위의 필어예요. 전달에 큰 방해는 되지 않아요."
        case 4...8:
            return "필러가 조금 느껴져요. 문장 사이에 짧은 호흡을 넣어보면 좋아요."
        default:
            return "필러가 자주 등장해요. '음' 대신 잠깐 멈추는 연습을 해보면 효과가 클 것 같아요."
        }
    }
}
