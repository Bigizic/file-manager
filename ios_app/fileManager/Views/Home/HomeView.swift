//
//  HomeView.swift
//  fileManager
//
//  Home screen
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var serverViewModel = ServerConnectionViewModel()
    @State private var showServerConnection = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Welcome to File Explorer")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Choose an option to get started")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: FileExplorerView()) {
                            HomeButton(
                                icon: "folder.fill",
                                title: "File Explorer",
                                description: "Browse and download files from your system"
                            )
                        }
                        
                        NavigationLink(destination: NotesListView()) {
                            HomeButton(
                                icon: "note.text",
                                title: "Notes",
                                description: "Create, edit, and manage your notes"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Home")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showServerConnection = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 14))
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            (colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                .background(.ultraThinMaterial)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showServerConnection) {
                ServerConnectionView()
            }
            .onAppear {
                serverViewModel.loadSavedServer()
            }
        }
    }
}

struct HomeButton: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.separator), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
}
