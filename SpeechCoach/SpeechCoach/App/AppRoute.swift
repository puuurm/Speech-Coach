//
//  AppRoute.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/12/25.
//

import Foundation

enum AppRoute: Hashable {
    case videoPlayer(SpeechDraft)
    case result(SpeechRecord)
}
