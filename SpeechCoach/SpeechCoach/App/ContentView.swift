//
//  ContentView.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/21/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var recordStore = SpeechRecordStore()
    @StateObject private var router = NavigationRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: homeViewModel)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .videoPlayer(let draft):
                        VideoPlayerScreen(draft: draft)
                    case .result(let record):
                        ResultScreen(record: record)
                    }
                }
        }
        .environmentObject(recordStore)
        .environmentObject(router)
    }
}

#Preview {
    ContentView()
}
