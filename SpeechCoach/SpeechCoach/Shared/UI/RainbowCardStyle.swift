//
//  RainbowCardStyle.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/7/26.
//

import SwiftUI

struct RainbowCardStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        let opacity: Double = 0.4
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(opacity),
                                Color.blue.opacity(opacity),
                                Color.cyan.opacity(opacity),
                                Color.green.opacity(opacity),
                                Color.yellow.opacity(opacity),
                                Color.orange.opacity(opacity),
                                Color.pink.opacity(opacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
    }
}

extension View {
    func rainbowCardStyle() -> some View {
        modifier(RainbowCardStyle())
    }
}
