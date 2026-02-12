//
//  CrashLogging.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/12/26.
//

import Foundation

protocol CrashLogging {
    func setValue(_ value: Any, forKey key: String)
    func log(_ message: String)
    func record(_ error: Error)
}

struct NoOptionsCrashLogger: CrashLogging {
    func setValue(_ value: Any, forKey key: String) {}
    func log(_ message: String) {}
    func record(_ error: any Error) {}
}
