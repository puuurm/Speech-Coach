//
//  TranscriptAnalyzer.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/25/25.
//

import Foundation

struct TranscriptAnalyzer {
    private let fillerCandidates = ["음", "어", "그", "음...", "어...", "그..."]
    
    func wordsPerMinute(transcript: String, duration: TimeInterval) -> Int {
        let tokens = transcript
            .split { $0.isWhitespace || $0.isNewline }
        guard duration > 0 else { return 0 }
        let minutes = duration / 60.0
        guard minutes > 0 else { return 0 }
        
        return Int(Double(tokens.count) / minutes)
    }
    
    func fillerCount(in transcript: String) -> Int {
        let tokens = transcript
            .split { $0.isWhitespace || $0.isNewline }
            .map(String.init)
        return tokens.filter { fillerCandidates.contains($0) }.count
    }
    
    func extractFillers(from transcript: String) -> [String] {
        let words = transcript.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { fillerCandidates.contains($0) }
    }
    
    func fillerWordsDict(from transcript: String) -> [String: Int] {
        let words = transcript.components(separatedBy: .whitespacesAndNewlines)
        
        var counts: [String: Int] = [:]
        for word in words {
            if fillerCandidates.contains(word) {
                counts[word, default: 0] += 1
            }
        }
        return counts
    }
}
