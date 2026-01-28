//
//  AllRecordsView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/27/26.
//

import SwiftUI

struct AllRecordsView: View {
    @EnvironmentObject var recordStore: SpeechRecordStore
    @EnvironmentObject var router: NavigationRouter

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)],
        animation: .default
    )
    private var recordEntities: FetchedResults<SpeechRecordEntity>

    private var records: [SpeechRecord] {
        recordEntities.compactMap(SpeechRecordMapper.toDomain)
    }

    private let grouper = RecentRecordsGrouper()

    var body: some View {
        let sections = grouper.makeSections(from: records)

        List {
            ForEach(sections) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.records) { record in
                        Button {
                            router.push(.result(recordID: record.id))
                        } label: {
                            RecentRecordRow(record: record)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(
                            EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                recordStore.delete(record)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .navigationTitle("전체 기록")
        .navigationBarTitleDisplayMode(.inline)
    }
}
