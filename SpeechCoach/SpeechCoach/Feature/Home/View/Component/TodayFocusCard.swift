//
//  TodayFocusCard.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 3/4/26.
//

import SwiftUI
import PhotosUI

struct TodayFocusCard: View {
    let text: String
    @Binding var selectedItem: PhotosPickerItem?
    
    let onTapDone: () -> Void
    let onTapOpenRelated: () -> Void
    
    @State private var showCompleteAlert = false
    @State private var isCompleting = false
    
    private let cardPadding: CGFloat = 20
    private let checkButtonSize: CGFloat = 32
    private let overlayInset: CGFloat = 9
    private let actionSpacing: CGFloat = 10
    private let actionTopPadding: CGFloat = 16
    private let buttonCornerRadius: CGFloat = 12
    private let relatedButtonSize: CGFloat = 44
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            titleSection
            descriptionSection
            focusTextSection
            actionSection
        }
        .padding(cardPadding)
        .alert("오늘의 할 일 마치셨나요?", isPresented: $showCompleteAlert) {
            Button("취소", role: .cancel) { }
            Button("확인") {
                runCompleteAnimationThenDismiss()
            }
        } message: {
            Text("완료로 표시하면 오늘의 한 가지 카드가 홈에서 사라져요.")
        }
        .overlay(alignment: .topTrailing) {
            completeButton
                .padding(.top, overlayInset)
                .padding(.trailing, overlayInset)
        }
    }
    
    private func runCompleteAnimationThenDismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            isCompleting = true
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onTapDone()
        }
    }
}

// MARK: - Sections
extension TodayFocusCard {
    var titleSection: some View {
        Text("오늘의 한 가지")
            .font(.headline)
    }
    
    var descriptionSection: some View {
        Text("다음 영상에서 이것만 의식해보세요.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    var focusTextSection: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    var actionSection: some View {
        HStack(spacing: actionSpacing) {
            practiceButton
            relatedButton
        }
        .padding(.top, actionTopPadding)
    }
}

// MARK: - Buttons
extension TodayFocusCard {
    var completeButton: some View {
        Button {
            guard isCompleting == false else { return }
            showCompleteAlert = true
        } label: {
            Image(systemName: isCompleting ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isCompleting ? Color.green : .secondary)
                .frame(width: checkButtonSize, height: checkButtonSize)
                .contentShape(Rectangle())
                .scaleEffect(isCompleting ? 1.2 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCompleting)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오늘의 할 일 완료하기")
    }
    
    var practiceButton: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .videos,
            photoLibrary: .shared()
        ) {
            HStack(spacing: 6) {
                Image(systemName: "play.rectangle.on.rectangle")
                
                Text("바로 연습하기")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(buttonBackground)
            .overlay(buttonBorder(cornerRadius: buttonCornerRadius))
            .cornerRadius(buttonCornerRadius)
        }
        .buttonStyle(.plain)
    }
    
    var relatedButton: some View {
        Button {
            onTapOpenRelated()
        } label: {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .frame(width: relatedButtonSize, height: relatedButtonSize)
                .background(buttonBackground)
                .overlay(buttonBorder(cornerRadius: buttonCornerRadius))
                .cornerRadius(buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("관련 결과 보기")
    }
}

// MARK: - Styling Helpers
extension TodayFocusCard {
    var buttonBackground: some View {
        Color.white
    }
    
    func buttonBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color(.systemGray4), lineWidth: 1)
    }
}
