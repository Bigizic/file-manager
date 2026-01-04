//
//  HomeView.swift
//  fileManager
//
//  Home screen with theme selector
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @StateObject private var serverViewModel = ServerConnectionViewModel()
    @State private var showServerConnection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Welcome to File Explorer")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text("Choose an option to get started")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    // Theme Selector
                    ThemeSelectorView()
                        .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: FileExplorerView()) {
                            HomeButton(
                                icon: "folder.fill",
                                title: "File Explorer",
                                description: "Browse and download files from your system",
                                theme: themeManager.currentTheme
                            )
                        }
                        
                        NavigationLink(destination: NotesListView()) {
                            HomeButton(
                                icon: "note.text",
                                title: "Notes",
                                description: "Create, edit, and manage your notes",
                                theme: themeManager.currentTheme
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("File Explorer - Home")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showServerConnection = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showServerConnection) {
                ServerConnectionView()
                    .environmentObject(themeManager)
            }
            .onAppear {
                serverViewModel.loadSavedServer()
            }
        }
        .applyTheme(themeManager.currentTheme)
    }
}

struct HomeButton: View {
    let icon: String
    let title: String
    let description: String
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(theme.accentColor)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.textColor.opacity(0.5))
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct ThemeSelectorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Use LazyVGrid for responsive layout that wraps to multiple rows
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ThemeType.allCases, id: \.self) { themeType in
                    ThemeButton(
                        themeType: themeType,
                        isSelected: themeManager.currentTheme.id == themeType,
                        theme: themeManager.currentTheme
                    ) {
                        themeManager.setTheme(themeType)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.cardBorderColor, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct ThemeButton: View {
    let themeType: ThemeType
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                } else {
                    Text("○")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColor.opacity(0.5))
                }
                
                Text(themeType.displayName)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? theme.textColor : theme.textColor.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? theme.accentColor.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? theme.accentColor : theme.borderColor.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AppState.shared)
}

