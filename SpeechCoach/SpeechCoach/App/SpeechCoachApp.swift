//
//  SpeechCoachApp.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/21/25.
//

import SwiftUI
import Firebase
import FirebaseCrashlytics

@main
struct SpeechCoachApp: App {
    let coreDataStack = CoreDataStack.shared
    
    init() {
        FirebaseApp.configure()
        configureCrashlytics()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.context)
                .environmentObject(
                              SpeechRecordStore(
                                  context: coreDataStack.context
                              )
                          )
        }
    }
}

// MARK: - Crashlytics
private func configureCrashlytics() {
    let key = "install_id"
    let id = UserDefaults.standard.string(forKey: key) ?? {
        let v = UUID().uuidString
        UserDefaults.standard.set(v, forKey: key)
        return v
    }()
    
    Crashlytics.crashlytics().setUserID(id)

    #if DEBUG
    Crashlytics.crashlytics().setCustomValue("debug", forKey: "build_type")
    #else
    Crashlytics.crashlytics().setCustomValue("release", forKey: "build_type")
    #endif
}
