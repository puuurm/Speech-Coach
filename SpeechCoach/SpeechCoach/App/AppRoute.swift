//
//  AppRoute.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/12/25.
//

import Foundation

struct VideoPlayerRoutePayload: Hashable {
    let videoURL: URL
    let title: String
    let duration: TimeInterval
    let startTime: TimeInterval?
    let autoplay: Bool
}

enum AppRoute: Hashable {
    case videoPlayer(VideoPlayerRoutePayload)
    case result(recordID: UUID)
    case allRecords
}
