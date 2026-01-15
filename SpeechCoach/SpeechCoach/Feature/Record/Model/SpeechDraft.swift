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

func wpmText(_ wpm: Int?) -> String {
    guard let wpm else { return "—" }
    return "\(wpm) wpm"
}

func fillerCountText(_ count: Int?) -> String {
    guard let count else { return "—" }
    return "\(count)회"
}

func cleanTitle(from raw: String) -> String {
    let base = raw
        .replacingOccurrences(of: ".mov", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    if UUID(uuidString: base) != nil {
        return "새 발표 영상"
    }
    
    return base
}

private let headerDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "M월 d일"
    return f
}()

func formattedDate(_ date: Date) -> String {
    headerDateFormatter.string(from: date)
}
