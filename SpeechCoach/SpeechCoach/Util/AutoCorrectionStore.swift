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

