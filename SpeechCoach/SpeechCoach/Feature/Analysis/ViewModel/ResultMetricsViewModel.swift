//
//  ResultMetricsViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/3/26.
//

import SwiftUI
import Combine

@MainActor
final class ResultMetricsViewModel: ObservableObject {

    @Published private(set) var metrics: SpeechMetrics?
    @Published private(set) var previousMetrics: SpeechMetrics?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let recordID: UUID
    
    init(recordID: UUID) {
        self.recordID = recordID
    }
    
    func load(using store: SpeechRecordStore, previousRecordID: UUID?) async {
        isLoading = true
        defer { isLoading = false }
        self.metrics = store.metrics(with: recordID)
        
        if let prevID = previousRecordID {
            self.previousMetrics = store.metrics(with: prevID)
        } else {
            self.previousMetrics = nil
        }
    }

    var wpmText: String {
        guard let m = metrics else { return "—" }
        return "\(m.wordsPerMinute) WPM"
    }

    var fillerText: String {
        guard let m = metrics else { return "—" }
        return "\(m.fillerCount)회"
    }

    var paceVariabilityText: String {
        guard let v = metrics?.paceVariability else { return "—" }
        return "\(Int((v * 100).rounded()))%"
    }

    var spikeText: String {
        guard let s = metrics?.spikeCount else { return "—" }
        return "\(s)회"
    }

    var topFillerWords: [(word: String, count: Int)] {
        guard let dict = metrics?.fillerWords else { return [] }
        return dict
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
}
