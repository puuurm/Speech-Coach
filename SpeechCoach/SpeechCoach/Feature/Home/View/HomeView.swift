//
//  HomeView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI
import PhotosUI
import AVFoundation
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context

    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var recordStore: SpeechRecordStore
    @EnvironmentObject var homeworkStore: HomeworkStore
    @EnvironmentObject var router: NavigationRouter
    @State private var selectedItem: PhotosPickerItem?
    @State private var navigateToPlayer = false
    @State private var isImporting: Bool = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)],
        animation: .default
    )
    
    private var recordEntities: FetchedResults<SpeechRecordEntity>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
        animation: .default
    )
    private var focusEntities: FetchedResults<DailyFocusEntity>
    
    private let padding: CGFloat = 20
    private let homeRecentLimit = 4
    
    private var allRecords: [SpeechRecord] {
        recordEntities.compactMap(SpeechRecordMapper.toDomain)
    }

    private var homeRecentRecords: [SpeechRecord] {
        Array(allRecords.prefix(homeRecentLimit))
    }
    
    private var todayFocusEntity: DailyFocusEntity? {
        let cal = Calendar.current
        return focusEntities.first(where: { entity in
            guard let d = entity.date else { return false }
            return cal.isDateInToday(d)
        })
    }
    
    private var todayFocus: DailyFocusEntity? {
        guard let entity = todayFocusEntity,
              let text = entity.text,
              text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        else { return nil }
        
        return entity
    }
    
    var body: some View {
        content
            .overlay {
                if isImporting {
                    Color.white
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(2.0)

                        Text("영상 불러오는 중이에요...")
                            .font(.callout)
                            .foregroundColor(.gray)
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
    }
    
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header("스피치 분석")
                
                if let entity = todayFocusEntity,
                   let text = entity.text,
                   text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                   entity.isDone == false {
                    TodayFocusCard(
                        text: text,
                        selectedItem: $selectedItem,
                        onTapDone: {
                            recordStore.completeDailyFocus(for: Date())
                        },
                        onTapOpenRelated: {
                            if let id = entity.recordID {
                                router.push(.result(recordID: id))
                            }
                        }
                    )
                    .rainbowCardStyle()
                }
                
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    primaryActionCard
                }
                .buttonStyle(.plain)
                .padding(padding)
                .cardStyle()

                sectionHeader("최근 분석", trailing: {
                    AnyView(
                        Button {
                            router.push(.allRecords)
                        } label: {
                            Text("전체 보기")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .opacity(allRecords.count > 4 ? 1 : 0)
                        .allowsHitTesting(allRecords.count > 4)
                    )
                })
                
                let preview = Array(allRecords.prefix(4))
                
                RecentAnalysisSection(
                    records: preview,
                    totalCount: allRecords.count,
                    onSelect: { router.push(.result(recordID: $0.id)) },
                    onDelete: { recordStore.delete($0) },
                    onTapAll: { router.push(.allRecords) }
                )
            }
        }
        .padding(padding)
    }
}

private extension HomeView {
    func header(_ title: String) -> some View {
        Text(title)
            .font(title == "스피치 분석" ? .title2.weight(.bold) : .title3.weight(.bold))
            .padding(.top, padding)
    }
    
    private func sectionHeader(
        _ title: String,
        trailing: (() -> AnyView)? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))

            Spacer()

            if let trailing {
                trailing()
            }
        }
        .padding(.top, padding)
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
    
    var primaryActionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("새 영상 분석하기")
                .font(.headline)
            Text("발표나 연습 영상을 불러와 \n내 말의 흐름과 핵심 지표를 확인해보세요.")
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
        .contentShape(Rectangle())
    }
    
    func handlePickedItem(_ item: PhotosPickerItem) async {
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
