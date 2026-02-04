//
//  ResultScreen.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 2/4/26.
//

import SwiftUI

struct ResultScreen: View {
    @StateObject private var viewModel: ResultViewModel
    @EnvironmentObject private var recordStore: SpeechRecordStore
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .loading:
                ProgressView("불러오는 중...")
            case .loaded:
                ResultLoadedView()
            case .failed(let message):
                Text(message)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await viewModel.load(using: recordStore)
        }
    }
}

private extension ResultScreen {
    
    func noteBinding<T>(
        _ keyPath: WritableKeyPath<NoteDraft, T>
    ) -> Binding<T> {
        Binding(
            get: {
                guard case let .loaded(loaded) = viewModel.state else {
                    fatalError("Invalid state access")
                }
                return loaded.note[keyPath: keyPath]
            },
            set: { newValue in
                viewModel.updateNote { note in
                    note[keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    private var introSection: some View {
        memoEditorRow(
            title: "한 줄 요약",
            buttonTitle: "예시",
            placeholder: "이 영상에서 가장 전하고 싶은 말을 한 문장으로 적어보세요.",
            text: noteBinding(\.introText)
        ) {
            let example = "결론부터 말하면, 핵심 문장을 더 또렷하게 전달하는 것이 목표입니다."
            
            viewModel.updateNote { note in
                if note.introText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    note.introText = example
                } else {
                    note.introText += "\n" + example
                }
            }
        }
    }

    func memoEditorRow(
        title: String,
        buttonTitle: String,
        placeholder: String,
        text: Binding<String>,
        onTemplateTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(buttonTitle) { onTemplateTap() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
            
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                TextEditor(text: text)
                    .font(.body)
                    .padding(8)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )
        }
    }
}
