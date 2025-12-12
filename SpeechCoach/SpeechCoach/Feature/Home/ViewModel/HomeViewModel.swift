//
//  HomeViewModel.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 11/22/25.
//

import Foundation
import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    @Published var recentRecords: [SpeechRecord] = []
}
