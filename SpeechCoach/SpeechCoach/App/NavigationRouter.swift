//
//  NavigationRouter.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/12/25.
//

import SwiftUI
import Combine

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func resetToRoot() {
        path = []
    }
    
    func navigateToVideoPlayer(
        record: SpeechRecord,
        startTime: TimeInterval? = nil,
        autoplay: Bool = true
    ) {
        push(.videoPlayer(.init(
            videoURL: record.resolvedVideoURL ?? .documentsDirectory,
            title: record.title,
            duration: record.duration,
            startTime: startTime,
            autoplay: autoplay
        )))
    }
    
    func navigateToVideoPlayer(
        draft: SpeechDraft,
        startTime: TimeInterval? = nil,
        autoplay: Bool = true
    ) {
        push(.videoPlayer(.init(
            videoURL: draft.videoURL,
            title: draft.title,
            duration: draft.duration,
            startTime: startTime,
            autoplay: autoplay
        )))
    }
}
