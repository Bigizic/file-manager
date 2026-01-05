//
//  FilePreviewView.swift
//  fileManager
//
//  File preview view for images and videos
//

import SwiftUI
import UIKit
import AVKit

struct FilePreviewView: View {
    let file: FileItem
    let currentPath: String
    let onCopy: () -> Void
    let onCut: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let onDownload: () -> Void
    let onInfo: () -> Void
    let hasClipboard: Bool
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FileExplorerViewModel()
    @State private var imageData: Data?
    @State private var videoURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if file.isVideo, let videoURL = videoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .edgesIgnoringSafeArea(.all)
                } else if file.isImage, let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    ScrollView {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Text("Preview not available")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: onCopy) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: onCut) {
                            Label("Cut", systemImage: "scissors")
                        }
                        
                        if hasClipboard {
                            Divider()
                            Button(action: {
                                Task {
                                    await viewModel.pasteFile(targetDirectory: currentPath)
                                }
                            }) {
                                Label("Paste", systemImage: "doc.on.clipboard")
                            }
                        }
                        
                        Divider()
                        
                        Button(action: onMove) {
                            Label("Move", systemImage: "folder")
                        }
                        
                        Button(action: onDownload) {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                        
                        Divider()
                        
                        Button(action: onInfo) {
                            Label("Information", systemImage: "info.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadPreview()
            }
        }
    }
    
    private func loadPreview() {
        Task {
            do {
                let data = try await NetworkService.shared.downloadFile(path: file.relativePath)
                await MainActor.run {
                    if file.isVideo {
                        // Save video to temporary file for AVPlayer
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
                        try? data.write(to: tempURL)
                        self.videoURL = tempURL
                    } else {
                        self.imageData = data
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    FilePreviewView(
        file: FileItem(
            id: "test",
            name: "test.jpg",
            path: "test.jpg",
            relativePath: "test.jpg",
            isDirectory: false,
            size: "1MB",
            modified: "2024-01-01",
            isImage: true,
            isVideo: false,
            isMedia: true
        ),
        currentPath: "",
        onCopy: {},
        onCut: {},
        onMove: {},
        onDelete: {},
        onDownload: {},
        onInfo: {},
        hasClipboard: false
    )
}
