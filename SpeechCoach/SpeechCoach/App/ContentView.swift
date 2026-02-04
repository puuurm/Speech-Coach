//
//  ContentView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/21/25.
//

import AlertToast
import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var homeworkStore = HomeworkStore()
    @EnvironmentObject private var recordStore: SpeechRecordStore
    @StateObject private var router = NavigationRouter()
    @StateObject private var pc = PlayerController()
    @State private var failedToSave = false
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: homeViewModel)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .videoPlayer(let payload):
                        VideoPlayerScreen(
                            videoURL: payload.videoURL,
                            title: payload.title,
                            startTime: payload.startTime,
                            autoplay: payload.autoplay
                        )
                        .environmentObject(pc)
                    case .result(let id):
                        ResultRootView(
                            recordID: id,
                            highlightContext: .homeAnalysis,
                            playbackPolicy: .hidden,
                            onRequestPlay: { sec in
                                pc.seek(to: sec, autoplay: true)
                            },
                            failedToSave: $failedToSave
                        )
                        .environmentObject(pc)
                    case .allRecords:
                        AllRecordsView()
                        
                    }
                }
        }
        .environmentObject(homeworkStore)
        .environmentObject(recordStore)
        .environmentObject(router)
        .toast(isPresenting: $failedToSave) {
            AlertToast(
                displayMode: .hud,
                type: .error(.red),
                title: "저장하지 못했어요"
            )
        }
    }
}


