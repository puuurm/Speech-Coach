//
//  MemoEditorRow.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/21/26.
//

import SwiftUI

struct MemoEditorRow: View {

    let title: String
    let buttonTitle: String
    let placeholder: String
    @Binding var text: String
    let onTemplateTap: (_ triggerHighlight: @escaping () -> Void) -> Void

    @State private var isHighlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)

                Spacer()

                Button(buttonTitle) {
                    onTemplateTap {
                        triggerHighlight()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accentColor)
            }

            ZStack(alignment: .topLeading) {

                Text(placeholder)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .opacity(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? 1
                        : 0
                    )
                    .animation(.easeOut(duration: 0.01), value: text)

                TextEditor(text: $text)
                    .font(.body)
                    .padding(8)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHighlighted
                        ? Color.primary.opacity(0.35)
                        : Color.secondary.opacity(0.25),
                        lineWidth: isHighlighted ? 1.3 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)
            )
            .shadow(
                color: isHighlighted
                    ? Color.black.opacity(0.06)
                    : Color.clear,
                radius: 6,
                x: 0,
                y: 2
            )
            .animation(.easeInOut(duration: 0.2), value: isHighlighted)


        }
    }

    private func triggerHighlight() {
        isHighlighted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isHighlighted = false
        }
    }
}

