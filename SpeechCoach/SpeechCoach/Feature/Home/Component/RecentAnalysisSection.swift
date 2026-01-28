//
//  RecentAnalysisSection.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/26/26.
//

import SwiftUI

struct RecentAnalysisSection: View {
    let records: [SpeechRecord]
    let totalCount: Int
    let onSelect: (SpeechRecord) -> Void
    let onDelete: (SpeechRecord) -> Void
    let onTapAll: () -> Void
    
//    private let grouper = RecentRecordsGrouper()

    var body: some View {
        if records.isEmpty {
            emptyRecentRow
                .cardStyle()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 0) {
                    ForEach(records) { record in
                        Button {
                            onSelect(record)
                        } label: {
                            RecentRecordRow(record: record)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())   
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                onDelete(record)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }

            }
        }
    }
    
    var emptyRecentRow: some View {
        emptyRecentAnalysisView
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 220)
            .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 24, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
    
    var emptyRecentAnalysisView: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("아직 분석한 영상이 없어요")
                .font(.subheadline.weight(.semibold))

            Text("영상 불러오기로\n첫 스피치 분석을 시작해보세요")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
}
