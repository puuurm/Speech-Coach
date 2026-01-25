//
//  ResultRecordViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/2/26.
//

import SwiftUI
import Combine

@MainActor
final class ResultRecordViewModel: ObservableObject {
    private let recordID: UUID
    
    @Published private(set) var record: SpeechRecord?
    @Published private(set) var isLoading = false

    init(recordID: UUID) {
        self.recordID = recordID
    }

    func load(using store: SpeechRecordStore) async {
        isLoading = true
        defer { isLoading = false }
        if let record = store.record(with: recordID) {
            self.record = record
        } else {
            self.record = store.records.first(where: { $0.id == recordID })
        }
    }
    
    func updateStudentName(_ raw: String, using store: SpeechRecordStore) async {
        guard var record else { return }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let value: String? = trimmed.isEmpty ? nil : trimmed
        
        record.studentName = value ?? "--"
        self.record = record
        
        do {
            try await store.updateStudentName(recordID: record.id, studentName: value)
        } catch {
            assertionFailure("Failed to update studentName: \(error)")
        }
    }
}
