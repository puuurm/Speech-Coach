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
    
    var body: some View {
        NavigationStack {
            HomeView(viewModel: homeViewModel)
        }
        .environmentObject(recordStore)
    }
}

#Preview {
    ContentView()
}
