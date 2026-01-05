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
    @StateObject private var viewModel = FileExplorerViewModel()
    @State private var currentPath: String = ""
    @State private var selectedFile: FileItem?
    @State private var showPreview = false
    @State private var showFileActions = false
    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var showCreateFileAlert = false
    @State private var showCreateFolderAlert = false
    @State private var showMoveSheet = false
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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else if let successMessage = viewModel.downloadSuccessMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
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
                                    .contextMenu {
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
                                                showMoveSheet = true
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
                        showMoveSheet = true
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
            .sheet(isPresented: $showMoveSheet) {
                if let file = fileToMove {
                    MoveFileView(
                        file: file,
                        currentPath: currentPath,
                        breadcrumbs: viewModel.breadcrumbs,
                        directories: viewModel.files.filter { $0.isDirectory },
                        onMove: { targetPath in
                            Task {
                                await viewModel.moveFile(file, targetDirectory: targetPath, currentPath: currentPath)
                                showMoveSheet = false
                            }
                        }
                    )
                }
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
    let directories: [FileItem]
    let onMove: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedPath: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Location") {
                    Text(currentPath.isEmpty ? "Root" : currentPath)
                        .foregroundColor(.secondary)
                }
                
                Section("Parent Directories") {
                    Button(action: {
                        onMove("")
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.accentColor)
                            Text("Root")
                            Spacer()
                        }
                    }
                    
                    ForEach(breadcrumbs) { breadcrumb in
                        if !breadcrumb.path.isEmpty {
                            Button(action: {
                                onMove(breadcrumb.path)
                            }) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.accentColor)
                                    Text(breadcrumb.name)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                if !directories.isEmpty {
                    Section("Subdirectories") {
                        ForEach(directories) { directory in
                            Button(action: {
                                onMove(directory.relativePath)
                            }) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.accentColor)
                                    Text(directory.name)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move \(file.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                await MainActor.run {
                    if file.isImage, let image = UIImage(data: data) {
                        // Create thumbnail
                        let thumbnailSize = CGSize(width: 100, height: 100)
                        self.thumbnail = image.preparingThumbnail(of: thumbnailSize) ?? image
                    } else if file.isVideo {
                        // Create video thumbnail
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
                        try? data.write(to: tempURL)
                        if let thumbnail = generateVideoThumbnail(url: tempURL) {
                            self.thumbnail = thumbnail
                        }
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                    self.isLoadingThumbnail = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingThumbnail = false
                }
            }
        }
    }
    
    private func generateVideoThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
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
