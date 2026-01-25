//
//  FullFlowHintBanner.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 1/14/26.
//

import SwiftUI

struct FullFlowHintBanner: View {
    let onTapWatchVideo: () -> Void
    let onTapDontShowAgain: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("전체 흐름을 확인한 뒤 피드백을 작성해 보세요")
                        .font(.subheadline.weight(.semibold))
                    
                    Text("전체를 보고 작성하면 톤/구조 피드백이 더 정확해져요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                Button(action: onTapWatchVideo) {
                    Text("영상 보기")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.9))
                        .foregroundStyle(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                            
                Button(action: onTapDontShowAgain) {
                    Text("다시 보지 않기")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}
