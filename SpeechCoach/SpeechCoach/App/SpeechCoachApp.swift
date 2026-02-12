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
    let crashLogger = FirebaseCrashLogger()
    
    init() {
        FirebaseApp.configure()
        CrashlyticsBootstrap.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(crashLogger: crashLogger)
                .environment(\.managedObjectContext, coreDataStack.context)
                .environment(\.crashLogger, crashLogger)
                .environmentObject(
                    SpeechRecordStore(
                        context: coreDataStack.context,
                        crashLogger: crashLogger
                    )
                )
        }
    }
}

// MARK: - Crashlytics
enum CrashlyticsBootstrap {
    static func configure() {
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
}
