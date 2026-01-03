//
//  ThemeExtensions.swift
//  fileManager
//
//  Theme application extensions
//

import SwiftUI

extension View {
    func applyTheme(_ theme: Theme) -> some View {
        self
            .foregroundColor(theme.textColor)
            .background(theme.backgroundColor)
    }
}

struct ThemedTextFieldStyle: TextFieldStyle {
    let theme: Theme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(theme.surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
            .cornerRadius(8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(theme.accentColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

