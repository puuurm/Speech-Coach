//
//  TranscriptCleaner.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/30/25.
//

import Foundation

enum TranscriptCleaner {
    static let replacements: [String: String] = [
        "지요": "집요",
        "지변": "집요함",
        "위험합니다": "유연함입니다",
        "티 언제가": "팀원들과",
        "대 도를": "태도를",
        "유연 합니다": "유연함입니다",
        "전복감": "접목한",
        "팀원 건": "팀원 간",
        "더 나은 제한을": "더 나은 제안을",
        "복지콕으로": "복식호흡으로",
        "빠르고": "따르고",
        "웹툰 쿠키 작가": "웹툰 콘티 작가",
        "중요하다고고": "중요하다고"
    ]
    
    static let junkCharacters = CharacterSet(charactersIn: ".,!?~…—[]{}<>·|※#%$^&*()_+=“”")

    static func applyReplacements(_ text: String) -> String {
        var result = text
        for (wrong, correct) in replacements {
            result = result.replacingOccurrences(of: wrong, with: correct)
        }
        return result
    }

    static func cleaned(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return "" }
        text = removeJunkCharacters(from: text)
        text = applyReplacements(text)
        text = normalizeWhitespace(in: text)
        text = removeNoiseNumbers(in: text)
        text = tidyPunctuation(in: text)
        text = splitByKoreanEndingsIfNeeded(text)
        text = AutoCorrectionStore.shared.apply(to: text)
        text = applyReplacements(text)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty == false,
            let last = text.unicodeScalars.last, !"。．.?!？！".unicodeScalars.contains(last) {
            text.append(".")
        }
        return text
    }
}

extension TranscriptCleaner {
    
    static func removeJunkCharacters(from text: String) -> String {
        // 정상적인 마침표(.)는 유지, 기타 특수문자 제거
        return text.components(separatedBy: junkCharacters).joined()
    }
    static func normalizeWhitespace(in text: String) -> String {
        var result = text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        let pattern = #" {2,}"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func removeNoiseNumbers(in text: String) -> String {
        var result = text
        let longNumberPattern = #"\d{6,}"#
        if let regex = try? NSRegularExpression(pattern: longNumberPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        let commaNumberPattern = #"\d{1,3}(,\d{3}){2,}"#
        if let regex = try? NSRegularExpression(pattern: commaNumberPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }
        result = normalizeWhitespace(in: result)
        return result
    }
    
    static func tidyPunctuation(in text: String) -> String {
        var result = text
        
        let multiDotPattern = #"\.{3,}"#
        if let regex = try? NSRegularExpression(pattern: multiDotPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "…")
        }
        let spaceBeforePunctPatter = #" +([\.?!])"#
        if let regex = try? NSRegularExpression(pattern: spaceBeforePunctPatter, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "$1")
        }
        let punctPattern = #"([\.?!])([^\s])"#
        if let regex = try? NSRegularExpression(pattern: punctPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1 $2")
        }
        
        return normalizeWhitespace(in: result)
    }
    
    static func splitByKoreanEndingsIfNeeded(_ text: String) -> String {
        if text.count < 80 {
            return text
        }
        var result = text
        let endings = [
            "합니다", "했습니다", "합니다만",
            "됩니다", "되었습니다",
            "입니다", "있습니다",
            "했어요", "됐어요", "됐습니다",
            "였어요", "었어요"
        ]
        
        for ending in endings {
            let pattern = "\(ending)(?= )"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: "\(ending)."
                )
            }
        }
        
        result = normalizeWhitespace(in: result)
        return result
    }
}
