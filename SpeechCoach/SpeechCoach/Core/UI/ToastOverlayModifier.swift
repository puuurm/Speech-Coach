//
//  ToastOverlayModifier.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/24/26.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var toastText: String?
    let alignment: Alignment
    let paddingTop: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if let toastText {
                    toastView(text: toastText)
                        .padding(.top, paddingTop)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
    }
    
    private func toastView(text: String) -> some View {
        Text(text)
            .font(.caption).bold()
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 6)
    }
    
}
