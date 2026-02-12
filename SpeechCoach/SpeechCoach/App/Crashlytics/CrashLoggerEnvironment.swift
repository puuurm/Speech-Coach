//
//  CrashLoggerEnvironment.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/12/26.
//

import SwiftUI

private struct CrashLoggerKey: EnvironmentKey {
    static let defaultValue: CrashLogging = NoOptionsCrashLogger()
}

extension EnvironmentValues {
    var crashLogger: CrashLogging {
        get {
            self[CrashLoggerKey.self]
        } set {
            self[CrashLoggerKey.self] = newValue
        }
    }
}
