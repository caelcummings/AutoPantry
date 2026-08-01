//
//  ContentView.swift
//  AutoPantry
//
//  Created by Cael Cummings on 5/10/26.
//

import SwiftUI

/// Legacy entry — the app launches `RootView` from `AutoPantryApp`.
/// Preview `RootView` or `OnboardingFlowView` instead.
struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview("App (Onboarding)") {
    ContentView()
        .environmentObject(AppState(route: .onboarding))
}

#Preview("App (Main)") {
    ContentView()
        .environmentObject(AppState(route: .main))
}
