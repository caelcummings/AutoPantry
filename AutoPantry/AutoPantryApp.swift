//
//  AutoPantryApp.swift
//  AutoPantry
//
//  Created by Cael Cummings on 5/10/26.
//

import SwiftUI

@main
struct AutoPantryApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
