//
//  SpeechRecord+Video.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/24/25.
//

import Foundation

extension SpeechRecord {
    var resolvedVideoURL: URL? {
        guard let path = videoRelativePath else { return nil }
        return VideoStore.shared.resolve(relativePath: path)
    }
    
    var isVideoAvailable: Bool {
        guard let path = videoRelativePath else { return false }
        return VideoStore.shared.exist(relativePath: path)
    }
}
