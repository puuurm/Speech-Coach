//
//  NavigationRouter.swift
//  SpeechCoach
//
//  Created by Heejung Yang on 12/12/25.
//

import SwiftUI
import Combine

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func resetToRoot() {
        path = []
    }
}
