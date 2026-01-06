//
//  HomeView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var recordStore: SpeechRecordStore
    @EnvironmentObject var router: NavigationRouter
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var navigateToPlayer = false
    
    @State private var isImporting: Bool = false
    
    var body: some View {
        content
            .overlay {
                if isImporting {
                    Color.white
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("영상 불러오는 중이에요...")
                            .font(.subheadline)
                    }
                }
            }
            .onChange(of: selectedItem) { newValue in
                guard let item = newValue else { return }
                isImporting = true
                Task {
                    await handlePickedItem(item)
                    await MainActor.run {
                        isImporting = false
                    }
                }
            }
            .navigationTitle("스피치 분석")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("🏠 Home sees records:", recordStore.records.count)
            }

    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("스피치 영상 도우미")
                .font(.title2.weight(.semibold))
            Text("학생 발표 영상을 불러와 텍스트와 지표로 빠르게 분석해요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var content: some View {
        List {
            Section {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos,
                    photoLibrary: .shared()) {
                        primaryActionCard
                    }
                    .buttonStyle(.plain)
            }
            recentSection
        }
        .listStyle(.insetGrouped)
        .listRowSeparator(.hidden)
        .navigationTitle("스피치 분석")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var primaryActionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("새 영상 분석하기")
                .font(.headline)
            Text("카톡으로 받은 학생 발표 영상을 사진 앱에 저장한 뒤, \n여기서 불러와 텍스트와 지표를 확인하세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "play.rectangle.on.rectangle")
                Text("영상 불러오기")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .font(.subheadline)
        }
        .padding(16)
    }
    
    private var recentSection: some View {
        Group {
            if recordStore.records.isEmpty {
                Section {
                    Text("아직 분석한 영상이 없어요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("최근 분석")
                        .font(.headline)
                }
            } else {
                let groupted = Dictionary(grouping: recordStore.records) { record in
                    dayKey(from: record.createdAt)
                }
                
                let sortedKeys = groupted.keys
                    .compactMap { date(fromDayKey: $0) }
                    .sorted(by: { $0 > $1 })
                
                Section {
                    EmptyView()
                } header: {
                    Text("최근 분석")
                        .font(.headline)
                }
                
                ForEach(sortedKeys, id: \.self) { date in
                    if let recordsForDay = groupted[dayKey(from: date)] {
                        let sortedRecords = recordsForDay.sorted(by: { $0.createdAt > $1.createdAt })
                        
                        Section {
                            ForEach(sortedRecords) { record in
                                Button {
                                    router.push(.result(recordID: record.id))
                                } label: {
                                    RecentRecordRow(record: record)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        recordStore.delete(record)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text(sectionHeaderTitle(for: date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }

    }
    
    private func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func date(fromDayKey key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
    
    private func sectionHeaderTitle(for date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: date)
        
        let comp = cal.dateComponents([.day], from: target, to: today)
        let diff = comp.day ?? 0
        
        switch diff {
        case 0:
            return "오늘"
        case 1:
            return "어제"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일 (E)"
            return formatter.string(from: date)
        }
    }
}

extension HomeView {
    private func handlePickedItem(_ item: PhotosPickerItem) async {
        do {
            guard let picked = try await item.loadTransferable(type: PickedVideo.self) else { return }
            
            let tempURL = picked.url
            
            let asset = AVAsset(url: tempURL)
            let seconds = CMTimeGetSeconds(asset.duration)
            let duration = seconds.isFinite ? seconds : 0

            let draft = SpeechDraft(
                id: UUID(),
                title: tempURL.lastPathComponent,
                duration: duration,
                videoURL: tempURL
            )
            
            await MainActor.run {
                router.navigateToVideoPlayer(draft: draft)
            }
            
        } catch {
            print("Video load error: \(error)")
        }
    }
}

//#Preview {
//    HomeView(path: [], viewModel: .init())
//}
