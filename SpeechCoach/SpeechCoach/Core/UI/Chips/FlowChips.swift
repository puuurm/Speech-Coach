//
//  FlowChips.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/16/25.
//

import SwiftUI

struct FlowChips<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                content
            }
        }
    }
}
