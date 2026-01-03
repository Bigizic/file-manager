//
//  ThemeManager.swift
//  fileManager
//
//  Manages theme selection and persistence
//

import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme {
        didSet {
            saveTheme()
        }
    }
    
    private let themeKey = "selectedTheme"
    
    private init() {
        if let savedThemeType = UserDefaults.standard.string(forKey: themeKey),
           let themeType = ThemeType(rawValue: savedThemeType) {
            self.currentTheme = Theme.theme(for: themeType)
        } else {
            self.currentTheme = Theme.retro
        }
    }
    
    func setTheme(_ themeType: ThemeType) {
        currentTheme = Theme.theme(for: themeType)
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.id.rawValue, forKey: themeKey)
    }
}

extension Theme {
    static func theme(for type: ThemeType) -> Theme {
        switch type {
        case .retro: return .retro
        case .robotic: return .robotic
        case .cyberpunk: return .cyberpunk
        case .saas: return .saas
        }
    }
}

