//
//  Haptics.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/24/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    #if canImport(UIKit)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    #else
    static func success() {}
    static func warning() {}
    static func error() {}
    static func impact(_ style: Any = ()) {}
    static func selection() {}
    #endif
}
