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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("오늘의 한 가지")
                    .font(.headline)

                Spacer()

                Button {
                    guard isCompleting == false else { return }
                    showCompleteAlert = true
                } label: {
                    Image(systemName: isCompleting ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCompleting ? Color.green : .secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                        .scaleEffect(isCompleting ? 1.2 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCompleting)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("오늘의 할 일 완료하기")
            }
            
            Text("다음 영상에서 이것만 의식해보세요.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
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
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button {
                    onTapOpenRelated()
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("관련 결과 보기")
            }
        }
        .padding(16)
        .cardStyle()
        .alert("오늘의 할 일 마치셨나요?", isPresented: $showCompleteAlert) {
            Button("취소", role: .cancel) { }
            Button("확인") {
                runCompleteAnimationThenDismiss()
            }
        } message: {
            Text("완료로 표시하면 오늘의 한 가지 카드가 홈에서 사라져요.")
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
