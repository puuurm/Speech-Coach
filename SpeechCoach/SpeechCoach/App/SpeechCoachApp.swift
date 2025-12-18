//
//  SpeechCoachApp.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/21/25.
//

import SwiftUI

@main
struct SpeechCoachApp: App {
    let seekBridge = HighlightSeekBridge.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(seekBridge)
        }
    }
}
