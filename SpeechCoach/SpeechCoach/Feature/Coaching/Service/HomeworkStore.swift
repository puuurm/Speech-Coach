//
//  HomeworkStore.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/20/26.
//

import SwiftUI
import Combine

final class HomeworkStore: ObservableObject {
    @Published private(set) var homeworks: [DailyHomework] = []
    
    private let calendar = Calendar.current
    
    func addTodayHomework(
        drillType: DrillType,
        sourceHighlightID: UUID
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        
        guard homeworks.contains(where: {
            $0.date == today && $0.sourceHighlughtID == sourceHighlightID
        }) == false else { return }
        
        let homework = DailyHomework(
            id: UUID(),
            date: today,
            drillType: drillType,
            sourceHighlughtID: sourceHighlightID,
            isCompleted: false
        )
        
        homeworks.append(homework)
        persist()
    }
    
    func isSavedToday(drillType: DrillType) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return homeworks.contains {
            $0.date == today && $0.drillType == drillType
        }
    }
    
    private let storageKey = "daily_homeworks"
    
    init() {
        load()
    }
    
    private func persist() {
        guard let data = try? JSONEncoder().encode(homeworks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([DailyHomework].self, from: data)
        else { return }
        
        homeworks = decoded
    }
}
