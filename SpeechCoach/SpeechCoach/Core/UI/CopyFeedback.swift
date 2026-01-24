//
//  CopyFeedback.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/24/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum CopyFeedback {
    static func copy(
        _ text: String,
        toastText: Binding<String?>,
        message: String = "복사했어요",
        dismissAfter: TimeInterval = 1.2,
        haptic: (() -> Void)? = nil
    ) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        
        haptic?()
        
        withAnimation(.spring()) {
            toastText.wrappedValue = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
            withAnimation(.easeInOut) {
                toastText.wrappedValue = nil
            }
        }
    }
}
