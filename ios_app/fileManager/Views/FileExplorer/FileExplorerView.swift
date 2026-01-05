//
//  FileExplorerView.swift
//  fileManager
//
//  File browser view
//

import SwiftUI

struct FileExplorerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FileExplorerViewModel()
    @State private var currentPath: String = ""
    @State private var selectedFile: FileItem?
    @State private var showPreview = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else if let error = viewModel.errorMessage {
                    FileExplorerErrorView(message: error) {
                        viewModel.loadFiles(path: currentPath)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Breadcrumb Navigation
                        if !viewModel.breadcrumbs.isEmpty {
                            BreadcrumbView(
                                breadcrumbs: viewModel.breadcrumbs
                            ) { path in
                                currentPath = path
                                viewModel.loadFiles(path: path)
                            }
                        }
                        
                        // File List
                        if viewModel.files.isEmpty {
                            EmptyStateView(
                                message: "No files or folders found"
                            )
                        } else {
                            List {
                                ForEach(viewModel.files) { file in
                                    FileRowView(
                                        file: file
                                    ) {
                                        handleFileTap(file: file)
                                    }
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                                }
                            }
                            .listStyle(PlainListStyle())
                            .background(Color(UIColor.systemBackground))
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
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadFiles(path: currentPath)
            }
            .sheet(item: $selectedFile) { file in
                FilePreviewView(file: file)
            }
        }
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: file.isDirectory ? "folder.fill" : fileIcon(for: file))
                    .font(.system(size: 24))
                    .foregroundColor(file.isDirectory ? .accentColor : .secondary)
                    .frame(width: 32, height: 32)
                
                // File Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        if !file.isDirectory {
                            Text(file.size)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(file.modified)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !file.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
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
                            .foregroundColor(.accentColor)
                    }
                    
                    if breadcrumb.id != breadcrumbs.last?.id {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FileExplorerErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FileExplorerView()
        .environmentObject(AppState.shared)
}
