//
//  CustomButton.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/13/26.
//

import SwiftUI

struct PrimaryFullWidthButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.85 : 1.0))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SecondaryFullWidthButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground).opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
