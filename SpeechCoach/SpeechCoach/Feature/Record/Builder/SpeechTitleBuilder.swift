//
//  SpeechTitleBuilder.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/3/25.
//

import Foundation

enum SpeechTitleBuilder {
    
    /// transcript와 날짜를 기반으로 리스트에 보여줄 title을 생성합니다.
    /// 1) transcript의 첫 문장을 뽑고
    /// 2) 너무 길면 잘라서 "…"을 붙이고
    /// 3) 아무 내용이 없으면 날짜 기반 기본 제목을 사용합니다.
    static func makeTitle(transcript: String, createdAt: Date) -> String {
        let trimmed = transcript
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1) transcript가 비어 있으면 날짜 기반 기본 제목
        guard trimmed.isEmpty == false else {
            return defaultTitle(for: createdAt)
        }
        
        // 2) 첫 문장 추출
        if let firstSentence = firstSentence(in: trimmed) {
            return clipped(firstSentence)
        } else {
            return clipped(trimmed)
        }
    }
}

// MARK: - Private helpers

extension SpeechTitleBuilder {
    
    /// 마침표/물음표/느낌표/줄바꿈 등을 기준으로 첫 문장을 잘라냅니다.
    private static func firstSentence(in text: String) -> String? {
        let separators: [Character] = [".", "?", "!", "…", "。", "？", "！"]
        
        if let index = text.firstIndex(where: { separators.contains($0) }) {
            let prefix = text[..<index]
            let sentence = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
            return sentence.isEmpty ? nil : sentence
        } else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// 너무 긴 문장은 maxLength 기준으로 잘라서 "…"을 붙입니다.
    private static func clipped(_ text: String, maxLength: Int = 32) -> String {
        guard text.count > maxLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        let prefix = text[text.startIndex..<endIndex]
        return prefix.trimmingCharacters(in: .whitespaces) + "…"
    }
    
    /// transcript가 없을 때 사용할 기본 제목
    private static func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        let dateString = formatter.string(from: date)
        return "\(dateString) 스피치 기록"
    }
}
