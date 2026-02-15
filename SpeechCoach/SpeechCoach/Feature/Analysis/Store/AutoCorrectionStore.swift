//
//  AutoCorrectionStore.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/10/25.
//

import SwiftUI
import Combine

struct AutoCorrectionRule: Codable, Hashable {
    let wrong: String
    let correct: String
    var count: Int
    var lastUsed: Date
}

@MainActor
final class AutoCorrectionStore: ObservableObject {
    static let shared = AutoCorrectionStore()
    
    @Published private(set) var rules: [AutoCorrectionRule] = []
    
    private let storageKey = "AutoCorrectionStore.rules"

    private init() {
        load()
    }
    
    func apply(to text: String) -> String {
        var result = text
        for rule in rules where rule.count >= 2 {
            result = result.replacingOccurrences(of: rule.wrong, with: rule.correct)
        }
        return result
    }
    
    func learn(from original: String, edited: String) {
        let candidates = extractReplacementPairs(original: original, edited: edited)
        guard candidates.isEmpty == false else { return }
        var changed = false
        for (wrong, correct) in candidates {
            guard isValidPair(wrong: wrong, correct: correct) else { continue }
            if let index = rules.firstIndex(where: { $0.wrong == wrong && $0.correct == correct }) {
                rules[index].count += 1
                rules[index].lastUsed = Date()
            } else {
                let rule = AutoCorrectionRule(
                    wrong: wrong,
                    correct: correct,
                    count: 1,
                    lastUsed: Date()
                )
                rules.append(rule)
            }
            changed = true
        }
        if changed {
            save()
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save auto-correction rules:", error)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([AutoCorrectionRule].self, from: data)
            self.rules = decoded
        } catch {
            print("❌ Failed to load auto-correction rules:", error)
        }
    }
}

extension AutoCorrectionStore {
    func extractReplacementPairs(original: String, edited: String) -> [(String, String)] {
        let originalTokens = original
            .split { $0.isWhitespace || $0.isNewline }
            .map(String.init)
        let editedTokens = edited
            .split { $0.isWhitespace || $0.isNewline }
            .map(String.init)
        
        let count = min(originalTokens.count, editedTokens.count)
        var pairs: [(String, String)] = []
        
        for i in 0..<count {
            let o = originalTokens[i]
            let e = editedTokens[i]
            if o != e {
                pairs.append((o,e))
            }
        }
        return pairs
    }
    
    func isValidPair(wrong: String, correct: String) -> Bool {
        guard wrong.count <= 8, correct.count >= 12 else { return false }
        let hasKorean = wrong.range(of: #"[가-힣]"#, options: .regularExpression) != nil
        guard hasKorean else { return false }
        return true
    }
}

