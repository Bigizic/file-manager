//
//  FileExplorerView.swift
//  fileManager
//
//  File browser view
//

import SwiftUI
import UniformTypeIdentifiers
import AVKit
import AVFoundation

struct FileExplorerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FileExplorerViewModel()
    @State private var currentPath: String = ""
    
    init() {
        // This will be set in onAppear
    }
    @State private var selectedFile: FileItem?
    @State private var showPreview = false
    @State private var showFileActions = false
    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var showCreateFileAlert = false
    @State private var showCreateFolderAlert = false
    @State private var renameText = ""
    @State private var newFileName = ""
    @State private var newFolderName = ""
    @State private var fileToRename: FileItem?
    @State private var fileToDelete: FileItem?
    @State private var fileToMove: FileItem?
    @State private var fileToShowInfo: FileItem?
    @State private var showFileInfo = false
    @State private var showDocumentPicker = false
    @State private var showFileSavePicker = false
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
        } else {
            fileListContent
        }
    }
    
    private var fileListContent: some View {
        VStack(spacing: 0) {
            // Breadcrumb Navigation

            
            // File List
            if viewModel.files.isEmpty {
                EmptyStateView(
                    message: "No files or folders found"
                )
            } else {
                fileListView
            }
        }
    }
    
    private var fileListView: some View {
        List {
            ForEach(viewModel.files) { file in
                FileRowView(file: file) {
                    handleFileTap(file: file)
                }
                .listRowBackground(Color(UIColor.secondarySystemBackground))
                .contextMenu {
                    fileContextMenu(for: file)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private func fileContextMenu(for file: FileItem) -> some View {
        FileContextMenu(
            file: file,
            hasClipboard: viewModel.clipboardPath != nil,
            onCopy: { Task { await viewModel.copyFile(file) } },
            onCut: { Task { await viewModel.cutFile(file) } },
            onRename: {
                fileToRename = file
                renameText = file.name
                showRenameAlert = true
            },
            onDelete: {
                fileToDelete = file
                showDeleteAlert = true
            },
            onMove: {
                fileToMove = file
            },
            onDownload: {
                Task {
                    await viewModel.downloadFile(file: file, relativePath: currentPath)
                }
            },
            onInfo: {
                fileToShowInfo = file
                showFileInfo = true
            }
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if viewModel.clipboardPath != nil {
                Button(action: {
                    Task {
                        await viewModel.pasteFile(targetDirectory: currentPath)
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundColor(.accentColor)
                }
            }
            
            Menu {
                Button(action: {
                    showCreateFileAlert = true
                }) {
                    Label("New File", systemImage: "doc.badge.plus")
                }
                
                Button(action: {
                    showCreateFolderAlert = true
                }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                
                Button(action: {
                    showDocumentPicker = true
                }) {
                    Label("Upload File", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.accentColor)
            }
            
            Button(action: {
                viewModel.loadFiles(path: currentPath)
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            mainContent
        }
        .navigationTitle("File Explorer")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if !currentPath.isEmpty {
                        // Navigate to parent directory
                        let pathComponents = currentPath.components(separatedBy: "/").filter { !$0.isEmpty }
                        if pathComponents.count > 1 {
                            let parentPath = pathComponents.dropLast().joined(separator: "/")
                            currentPath = parentPath
                            viewModel.loadFiles(path: parentPath)
                        } else {
                            // Go to root
                            currentPath = ""
                            viewModel.loadFiles(path: "")
                        }
                    } else {
                        // At root, dismiss/pop navigation if possible
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.clipboardPath != nil {
                        Button(action: {
                            Task {
                                await viewModel.pasteFile(targetDirectory: currentPath)
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Menu {
                        Button(action: {
                            showCreateFileAlert = true
                        }) {
                            Label("New File", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: {
                            showCreateFolderAlert = true
                        }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        
                        Button(action: {
                            showDocumentPicker = true
                        }) {
                            Label("Upload File", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.accentColor)
                    }
                    
                    Button(action: {
                        viewModel.loadFiles(path: currentPath)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentColor)
                    }
                }
        }
        .onAppear {
            viewModel.notificationManager = appState.notificationManager
            viewModel.loadFiles(path: currentPath)
        }
        .sheet(isPresented: $showFileInfo) {
                if let file = fileToShowInfo {
                    FileInfoView(file: file)
                }
            }
        .sheet(item: $selectedFile) { file in
                FilePreviewView(
                    file: file,
                    currentPath: currentPath,
                    onCopy: { Task { await viewModel.copyFile(file) } },
                    onCut: { Task { await viewModel.cutFile(file) } },
                    onMove: {
                        fileToMove = file
                    },
                    onDelete: {
                        fileToDelete = file
                        showDeleteAlert = true
                    },
                    onDownload: {
                        Task {
                            await viewModel.downloadFile(file: file, relativePath: currentPath)
                        }
                    },
                    onInfo: {
                        fileToShowInfo = file
                        showFileInfo = true
                    },
                    hasClipboard: viewModel.clipboardPath != nil
                )
            }
        .sheet(item: $fileToMove) { file in
                MoveFileView(
                    file: file,
                    currentPath: currentPath,
                    breadcrumbs: viewModel.breadcrumbs,
                    viewModel: viewModel,
                    onMove: { targetPath in
                        Task {
                            await viewModel.moveFile(file, targetDirectory: targetPath, currentPath: currentPath)
                            fileToMove = nil
                        }
                    }
                )
                .id(file.id) // Force new view instance when file changes
            }
        .alert("Rename", isPresented: $showRenameAlert) {
                TextField("New name", text: $renameText)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    if let file = fileToRename, !renameText.isEmpty {
                        Task {
                            await viewModel.renameFile(file, newName: renameText, currentPath: currentPath)
                        }
                    }
                }
            } message: {
                Text("Enter new name for \(fileToRename?.name ?? "item")")
            }
        .alert("Delete", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let file = fileToDelete {
                        Task {
                            await viewModel.deleteFile(file, currentPath: currentPath)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(fileToDelete?.name ?? "this item")?")
            }
        .alert("New File", isPresented: $showCreateFileAlert) {
                TextField("File name", text: $newFileName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newFileName.isEmpty {
                        Task {
                            await viewModel.createFile(fileName: newFileName, targetDirectory: currentPath)
                            newFileName = ""
                        }
                    }
                }
            } message: {
                Text("Enter file name")
            }
        .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newFolderName.isEmpty {
                        Task {
                            await viewModel.createFolder(folderName: newFolderName, targetDirectory: currentPath)
                            newFolderName = ""
                        }
                    }
                }
            } message: {
                Text("Enter folder name")
            }
        .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Start accessing security-scoped resource
                        guard url.startAccessingSecurityScopedResource() else {
                            viewModel.errorMessage = "Permission denied to access file"
                            return
                        }
                        defer {
                            url.stopAccessingSecurityScopedResource()
                        }
                        
                        Task {
                            do {
                                let data = try Data(contentsOf: url)
                                let fileName = url.lastPathComponent
                                await viewModel.uploadFile(
                                    fileData: data,
                                    fileName: fileName,
                                    targetDirectory: currentPath
                                )
                            } catch {
                                viewModel.errorMessage = "Failed to read file: \(error.localizedDescription)"
                            }
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
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
                await viewModel.downloadFile(file: file, relativePath: currentPath)
            }
        }
    }
}

struct FileContextMenu: View {
    let file: FileItem
    let hasClipboard: Bool
    let onCopy: () -> Void
    let onCut: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    let onDownload: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        Button(action: onCopy) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        Button(action: onCut) {
            Label("Cut", systemImage: "scissors")
        }
        
        if hasClipboard {
            Divider()
        }
        
        Button(action: onRename) {
            Label("Rename", systemImage: "pencil")
        }
        
        Button(action: onMove) {
            Label("Move", systemImage: "folder")
        }
        
        if !file.isDirectory {
            Button(action: onDownload) {
                Label("Download", systemImage: "arrow.down.circle")
            }
        }
        
        Divider()
        
        Button(action: onInfo) {
            Label("Information", systemImage: "info.circle")
        }
        
        Divider()
        
        Button(role: .destructive, action: onDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
}

struct MoveFileView: View {
    let file: FileItem
    let currentPath: String
    let breadcrumbs: [Breadcrumb]
    let viewModel: FileExplorerViewModel
    let onMove: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var navigationPath: String = "" // Start at root
    @State private var items: [FileItem] = []
    @State private var navigationBreadcrumbs: [Breadcrumb] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main content
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMsg = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text(errorMsg)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry") {
                                errorMessage = nil
                                loadDirectory(path: navigationPath)
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            // Breadcrumb navigation
                            if !navigationBreadcrumbs.isEmpty {
                                Section {
                                    // Root button
                                    Button(action: {
                                        navigateToPath("")
                                    }) {
                                        HStack {
                                            Image(systemName: "house.fill")
                                                .foregroundColor(.accentColor)
                                            Text("Root")
                                            Spacer()
                                        }
                                    }
                                    
                                    // Parent directories
                                    ForEach(navigationBreadcrumbs) { breadcrumb in
                                        if !breadcrumb.path.isEmpty {
                                            Button(action: {
                                                navigateToPath(breadcrumb.path)
                                            }) {
                                                HStack {
                                                    Image(systemName: "folder.fill")
                                                        .foregroundColor(.accentColor)
                                                    Text(breadcrumb.name)
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    Text("Navigation")
                                }
                            }
                            
                            // Current directory contents
                            if !items.isEmpty {
                                Section {
                                    ForEach(items) { item in
                                        if item.isDirectory {
                                            Button(action: {
                                                navigateToPath(item.relativePath)
                                            }) {
                                                HStack {
                                                    Image(systemName: "folder.fill")
                                                        .foregroundColor(.accentColor)
                                                        .font(.system(size: 20))
                                                    Text(item.name)
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    Text(navigationPath.isEmpty ? "Root Directory" : "Contents")
                                }
                            } else if !isLoading && errorMessage == nil {
                                Section {
                                    Text("No directories found")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Bottom buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onMove(navigationPath)
                    }) {
                        Text("Move Here")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Move \(file.name)")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Use task instead of onAppear to ensure it runs
                // Start at root
                navigationPath = ""
                loadDirectory(path: "")
            }
        }
    }
    
    private func navigateToPath(_ path: String) {
        navigationPath = path
        errorMessage = nil
        loadDirectory(path: path)
    }
    
    private func loadDirectory(path: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await viewModel.networkService.fetchFileList(path: path)
                
                await MainActor.run {
                    // Filter to show only directories
                    self.items = response.items.filter { $0.isDirectory }
                    self.navigationBreadcrumbs = response.breadcrumbs
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    let errorMsg: String
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(let code, let message):
                            errorMsg = message ?? "HTTP Error \(code)"
                        case .invalidURL:
                            errorMsg = "Invalid URL"
                        case .invalidResponse:
                            errorMsg = "Invalid response from server"
                        case .decodingError(let decodingError):
                            errorMsg = "Failed to parse response: \(decodingError.localizedDescription)"
                        }
                    } else {
                        errorMsg = error.localizedDescription
                    }
                    self.items = []
                    self.navigationBreadcrumbs = []
                    self.isLoading = false
                    self.errorMessage = errorMsg
                }
            }
        }
    }
}

struct FileRowView: View {
    let file: FileItem
    let action: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var isLoadingThumbnail = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail or Icon
                if file.isDirectory {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .frame(width: 50, height: 50)
                } else if file.isImage || file.isVideo {
                    Group {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else if isLoadingThumbnail {
                            ProgressView()
                        } else {
                            Image(systemName: file.isImage ? "photo.fill" : "video.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                    .clipped()
                } else {
                    Image(systemName: fileIcon(for: file))
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 50)
                }
                
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
        .onAppear {
            if (file.isImage || file.isVideo) && thumbnail == nil && !isLoadingThumbnail {
                loadThumbnail()
            }
        }
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
    
    private func loadThumbnail() {
        isLoadingThumbnail = true
        Task {
            do {
                let data = try await NetworkService.shared.downloadFile(path: file.relativePath)
                
                if file.isImage, let image = UIImage(data: data) {
                    // Create thumbnail
                    let thumbnailSize = CGSize(width: 100, height: 100)
                    let thumbnail = await image.byPreparingThumbnail(ofSize: thumbnailSize) ?? image
                    await MainActor.run {
                        self.thumbnail = thumbnail
                        self.isLoadingThumbnail = false
                    }
                } else if file.isVideo {
                    // Create video thumbnail
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
                    try? data.write(to: tempURL)
                    let thumbnail = await generateVideoThumbnail(url: tempURL)
                    try? FileManager.default.removeItem(at: tempURL)
                    await MainActor.run {
                        if let thumbnail = thumbnail {
                            self.thumbnail = thumbnail
                        }
                        self.isLoadingThumbnail = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingThumbnail = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingThumbnail = false
                }
            }
        }
    }
    
    private func generateVideoThumbnail(url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        return await withCheckedContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: CMTime.zero) { cgImage, actualTime, error in
                if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
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

#Preview {
    FileExplorerView()
        .environmentObject(AppState.shared)
}

