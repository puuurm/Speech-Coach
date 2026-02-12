//
//  FirebaseCrashLogger.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/12/26.
//

import FirebaseCrashlytics

struct FirebaseCrashLogger: CrashLogging {
    func setValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    func record(_ error: any Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}
