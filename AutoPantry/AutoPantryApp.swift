//
//  AutoPantryApp.swift
//  AutoPantry
//
//  Created by Cael Cummings on 5/10/26.
//

import SwiftUI

@main
struct AutoPantryApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                appState.persistSessionState()
            }
        }
    }
}
