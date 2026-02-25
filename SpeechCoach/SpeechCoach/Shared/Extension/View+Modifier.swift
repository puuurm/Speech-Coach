//
//  View+Modifier.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/24/26.
//

import SwiftUI

extension View {
    func toastHost(
        toastText: Binding<String?>,
        alignment: Alignment = .top,
        paddingTop: CGFloat = 8
    ) -> some View {
        modifier(
            ToastModifier(
                toastText: toastText,
                alignment: alignment,
                paddingTop: paddingTop
            )
        )
    }
    
    func dismissKeyboardOnAnyTap() -> some View {
        self.contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            )
    }
}
