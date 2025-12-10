//
//  SpeechDraft.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import SwiftUI

struct SpeechDraft: Hashable {
    let id: UUID
    let title: String
    var duration: TimeInterval
    let videoURL: URL
    let thumbnail: UIImage? = nil
}

func durationString(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let sec = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, sec)
}

func cleanTitle(from raw: String) -> String {
    // 확장자 제거
    let base = raw
        .replacingOccurrences(of: ".mov", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // UUID면 사람이 알아보기 힘드니까 고정 문구로
    if UUID(uuidString: base) != nil {
        return "새 발표 영상"
    }
    
    return base
}
