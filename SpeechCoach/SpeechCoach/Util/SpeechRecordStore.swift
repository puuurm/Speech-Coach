//
//  SpeechRecordStore.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/26/25.
//

import Foundation
import Combine

final class SpeechRecordStore: ObservableObject {
    @Published private(set) var records: [SpeechRecord] = []
    
    private let storageKey = "SpeechRecordStore.recentRecords"
    
    init() {
        load()
    }
    
    func add(_ record: SpeechRecord) {
        records.insert(record, at: 0)
        if records.count > 20 {
            records.removeLast(records.count - 20)
        }
        save()
    }
    
    func updateNotes(
        for id: UUID,
        intro: String,
        strenghts: String,
        improvements: String,
        nextStep: String
    ) {
        guard let index = records.firstIndex(where: {$0.id == id}) else { return }
        records[index].noteIntro = intro
        records[index].noteStrengths = strenghts
        records[index].noteImprovements = improvements
        records[index].noteNextStep = nextStep
        save()
        print("Updated notes for record: ", id)
    }
    
    func previousRecord(before id: UUID) -> SpeechRecord? {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return nil }
        let nextIndex = index + 1
        guard records.indices.contains(nextIndex) else { return nil }
        return records[nextIndex]
    }
    
    func delete(_ record: SpeechRecord) {
        records.removeAll { $0.id == record.id }
        save()
        print("🗑 Deleted record:", record.id)
    }
    
    func deleteAll() {
        records.removeAll()
        save()
        print("🧹 Cleared all records")
    }
    
    func clear() {
        records.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save SpeechRecord list:", error)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([SpeechRecord].self, from: data)
            records = decoded
        } catch {
            print("Failed to load SpeechRecord list:", error)
        }
    }
}
