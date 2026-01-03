//
//  fileManagerApp.swift
//  fileManager
//
//  Created on iOS 18+
//

import SwiftUI

@main
struct FileManagerApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(appState)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}

