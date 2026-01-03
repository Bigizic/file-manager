//
//  Theme.swift
//  fileManager
//
//  Theme model and definitions
//

import SwiftUI

enum ThemeType: String, CaseIterable, Codable {
    case retro = "retro"
    case robotic = "robotic"
    case cyberpunk = "cyberpunk"
    case saas = "saas"
    
    var displayName: String {
        switch self {
        case .retro: return "Retro (Default)"
        case .robotic: return "Robotic"
        case .cyberpunk: return "Cyberpunk"
        case .saas: return "Modern SaaS"
        }
    }
}

struct Theme: Identifiable {
    let id: ThemeType
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let surfaceColor: Color
    let textColor: Color
    let accentColor: Color
    let borderColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: Color
    let colorScheme: ColorScheme?
    let font: Font
    
    static let retro = Theme(
        id: .retro,
        name: "Retro",
        primaryColor: Color(hex: "#000080"),
        secondaryColor: Color(hex: "#1084d0"),
        backgroundColor: Color(hex: "#c0c0c0"),
        surfaceColor: Color.white,
        textColor: Color.black,
        accentColor: Color(hex: "#316ac5"),
        borderColor: Color(hex: "#808080"),
        cardBackgroundColor: Color(hex: "#f0f0f0"),
        cardBorderColor: Color(hex: "#c0c0c0"),
        colorScheme: nil,
        font: .system(size: 14, design: .default)
    )
    
    static let robotic = Theme(
        id: .robotic,
        name: "Robotic",
        primaryColor: Color(hex: "#00ff00"),
        secondaryColor: Color(hex: "#00cc00"),
        backgroundColor: Color(hex: "#0a0a0a"),
        surfaceColor: Color(hex: "#0d0d0d"),
        textColor: Color(hex: "#00ff00"),
        accentColor: Color(hex: "#006600"),
        borderColor: Color(hex: "#00ff00"),
        cardBackgroundColor: Color(hex: "#0a0a0a"),
        cardBorderColor: Color(hex: "#00ff00"),
        colorScheme: .dark,
        font: .system(size: 14, design: .monospaced)
    )
    
    static let cyberpunk = Theme(
        id: .cyberpunk,
        name: "Cyberpunk",
        primaryColor: Color(hex: "#ff00ff"),
        secondaryColor: Color(hex: "#00ffff"),
        backgroundColor: Color.black,
        surfaceColor: Color(hex: "#0a0a0a"),
        textColor: Color(hex: "#00ffff"),
        accentColor: Color(hex: "#ff00ff"),
        borderColor: Color(hex: "#ff00ff"),
        cardBackgroundColor: Color.black,
        cardBorderColor: Color(hex: "#ff00ff"),
        colorScheme: .dark,
        font: .system(size: 14, design: .default)
    )
    
    static let saas = Theme(
        id: .saas,
        name: "Modern SaaS",
        primaryColor: Color(hex: "#667eea"),
        secondaryColor: Color(hex: "#764ba2"),
        backgroundColor: Color(hex: "#f8fafc"),
        surfaceColor: Color.white,
        textColor: Color(hex: "#1e293b"),
        accentColor: Color(hex: "#667eea"),
        borderColor: Color(hex: "#e2e8f0"),
        cardBackgroundColor: Color.white,
        cardBorderColor: Color(hex: "#e2e8f0"),
        colorScheme: nil,
        font: .system(size: 14, design: .default)
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

