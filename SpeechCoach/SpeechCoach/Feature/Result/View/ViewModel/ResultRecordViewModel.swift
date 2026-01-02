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

    @Published private(set) var record: SpeechRecord?
    @Published private(set) var isLoading = false

    private let recordID: UUID
    private let store: SpeechRecordStore

    init(recordID: UUID, store: SpeechRecordStore) {
        self.recordID = recordID
        self.store = store
    }

    func load() {
        isLoading = true
//        record = store.fetch(recordID: recordID)
        isLoading = false
    }
}
