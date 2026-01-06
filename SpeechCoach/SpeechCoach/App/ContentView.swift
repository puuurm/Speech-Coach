//
//  ContentView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/21/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @EnvironmentObject private var recordStore: SpeechRecordStore
    @StateObject private var router = NavigationRouter()
    @StateObject private var pc = PlayerController()
    
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
                        ResultScreen(
                            recordID: id,
                            playbackPolicy: .hidden,
                            onRequestPlay: { sec in
                                pc.seek(to: sec, autoplay: true)
                            }
                        )
                        .environmentObject(pc)
                    }
                }
        }
        .environmentObject(recordStore)
        .environmentObject(router)
    }
}


