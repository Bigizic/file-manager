//
//  ContentView.swift
//  fileManager
//
//  Main content view that handles navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: TabSelection = .home
    
    enum TabSelection {
        case home
        case explorer
        case notes
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(TabSelection.home)
            
            FileExplorerView()
                .tabItem {
                    Label("Explorer", systemImage: "folder.fill")
                }
                .tag(TabSelection.explorer)
            
            NotesListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(TabSelection.notes)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}

