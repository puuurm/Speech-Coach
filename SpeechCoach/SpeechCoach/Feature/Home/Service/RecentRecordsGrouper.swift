//
//  RecentRecordsGrouper.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//

import SwiftUI

struct RecentRecordsSection: Identifiable {
    let id: Date
    let title: String
    let records: [SpeechRecord]
}

struct RecentRecordsGrouper {
    private let calendar = Calendar.current
    private let locale = Locale(identifier: "ko_KR")

    func makeSections(from records: [SpeechRecord]) -> [RecentRecordsSection] {
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.createdAt)
        }

        let sortedDates = grouped.keys.sorted(by: >)

        return sortedDates.map { date in
            let dayRecords = (grouped[date] ?? []).sorted { $0.createdAt > $1.createdAt }
            return RecentRecordsSection(
                id: date,
                title: sectionHeaderTitle(for: date),
                records: dayRecords
            )
        }
    }

    private func sectionHeaderTitle(for date: Date) -> String {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)

        let diff = calendar.dateComponents([.day], from: target, to: today).day ?? 0
        switch diff {
        case 0: return "오늘"
        case 1: return "어제"
        default:
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateFormat = "M월 d일 (E)"
            return formatter.string(from: date)
        }
    }
}

