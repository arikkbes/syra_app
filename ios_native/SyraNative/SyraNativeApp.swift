// SyraNativeApp.swift
// iOS-FULL-2: Main app entry point with AppState

import SwiftUI

@main
struct SyraNativeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootContainer()
                .environmentObject(appState)
        }
    }
}
