//
//  FileExplorerView.swift
//  fileManager
//
//  File browser view
//

import SwiftUI

struct FileExplorerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FileExplorerViewModel()
    @State private var currentPath: String = ""
    @State private var selectedFile: FileItem?
    @State private var showPreview = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error, theme: themeManager.currentTheme) {
                        viewModel.loadFiles(path: currentPath)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Breadcrumb Navigation
                        if !viewModel.breadcrumbs.isEmpty {
                            BreadcrumbView(
                                breadcrumbs: viewModel.breadcrumbs,
                                theme: themeManager.currentTheme
                            ) { path in
                                currentPath = path
                                viewModel.loadFiles(path: path)
                            }
                        }
                        
                        // File List
                        if viewModel.files.isEmpty {
                            EmptyStateView(
                                message: "No files or folders found",
                                theme: themeManager.currentTheme
                            )
                        } else {
                            List {
                                ForEach(viewModel.files) { file in
                                    FileRowView(
                                        file: file,
                                        theme: themeManager.currentTheme
                                    ) {
                                        handleFileTap(file: file)
                                    }
                                    .listRowBackground(themeManager.currentTheme.surfaceColor)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .background(themeManager.currentTheme.backgroundColor)
                        }
                    }
                }
            }
            .navigationTitle("File Explorer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadFiles(path: currentPath)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadFiles(path: currentPath)
            }
            .sheet(item: $selectedFile) { file in
                FilePreviewView(file: file, theme: themeManager.currentTheme)
            }
        }
        .applyTheme(themeManager.currentTheme)
    }
    
    private func handleFileTap(file: FileItem) {
        if file.isDirectory {
            currentPath = file.relativePath
            viewModel.loadFiles(path: file.relativePath)
        } else if file.isMedia {
            selectedFile = file
            showPreview = true
        } else {
            // Download file
            Task {
                await viewModel.downloadFile(file: file)
            }
        }
    }
}

struct FileRowView: View {
    let file: FileItem
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: file.isDirectory ? "folder.fill" : fileIcon(for: file))
                    .font(.system(size: 24))
                    .foregroundColor(file.isDirectory ? theme.accentColor : theme.textColor.opacity(0.7))
                    .frame(width: 32, height: 32)
                
                // File Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        if !file.isDirectory {
                            Text(file.size)
                                .font(.system(size: 12))
                                .foregroundColor(theme.textColor.opacity(0.6))
                        }
                        
                        Text(file.modified)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textColor.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if !file.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColor.opacity(0.4))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func fileIcon(for file: FileItem) -> String {
        if file.isImage {
            return "photo.fill"
        } else if file.isVideo {
            return "video.fill"
        } else {
            return "doc.fill"
        }
    }
}

struct BreadcrumbView: View {
    let breadcrumbs: [Breadcrumb]
    let theme: Theme
    let onTap: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(breadcrumbs) { breadcrumb in
                    Button(action: {
                        onTap(breadcrumb.path)
                    }) {
                        Text(breadcrumb.name)
                            .font(.system(size: 14))
                            .foregroundColor(theme.accentColor)
                    }
                    
                    if breadcrumb.id != breadcrumbs.last?.id {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textColor.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(theme.surfaceColor)
    }
}

struct EmptyStateView: View {
    let message: String
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(theme.textColor.opacity(0.3))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(theme.textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    let theme: Theme
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry", action: retryAction)
                .buttonStyle(PrimaryButtonStyle(theme: theme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FileExplorerView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AppState.shared)
}

