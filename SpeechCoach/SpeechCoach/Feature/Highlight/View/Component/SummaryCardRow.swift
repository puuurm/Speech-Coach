//
//  SummaryCardRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/31/25.
//

import SwiftUI

//struct SummaryCardsRow: View {
//    let record: SpeechRecord
//
//    var scriptSummary: ScriptMatchSummary? { record.scriptMatchSummary }
//    var nonverbal: NonverbalSummary? { record.nonverbalSummary }
//
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 10) {
//
//                SummaryCard(
//                    title: "말하기 속도",
//                    value: "\(record.wordsPerMinute) WPM",
//                    footnote: speedHint(wpm: record.wordsPerMinute)
//                )
//
//                SummaryCard(
//                    title: "톤/변동",
//                    value: toneValueText(record: record),
//                    footnote: toneHintText(record: record)
//                )
//
//                SummaryCard(
//                    title: "필러",
//                    value: "\(record.fillerCount)",
//                    footnote: fillerHint(count: record.fillerCount)
//                )
//
//                SummaryCard(
//                    title: "대본 매칭",
//                    value: scriptSummary.map { "\($0.readingStyle.label)" } ?? "준비중",
//                    footnote: scriptSummary.map { "읽기 \(Int($0.readingScore*100)) · 키워드 \(Int($0.keywordRetention*100))" } ?? "대본 입력/분석 연결 필요"
//                )
//
//                SummaryCard(
//                    title: "표정",
//                    value: nonverbal.map { $0.tension.label } ?? "준비중",
//                    footnote: nonverbal.map { "표정 다양성 \(Int($0.expressionVariety*100))" } ?? "Vision/모델 연결 필요"
//                )
//            }
//            .padding(.vertical, 4)
//        }
//    }
//
//    private func speedHint(wpm: Int) -> String {
//        if wpm >= 170 { return "조금 빠름" }
//        if wpm <= 110 { return "조금 느림" }
//        return "적정"
//    }
//
//    private func fillerHint(count: Int) -> String {
//        if count >= 20 { return "의식적으로 줄이기" }
//        if count >= 10 { return "중간중간 정리" }
//        return "양호"
//    }
//
//    private func toneValueText(record: SpeechRecord) -> String {
//        // 이미 네 앱에 톤 지표가 있다면 그걸 연결
//        // (예: pitchVarianceScore 같은 값)
//        return "양호"
//    }
//
//    private func toneHintText(record: SpeechRecord) -> String {
//        return "단조로움 감지 기반"
//    }
//}
//
