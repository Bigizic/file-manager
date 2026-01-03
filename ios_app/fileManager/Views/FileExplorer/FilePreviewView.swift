//
//  FilePreviewView.swift
//  fileManager
//
//  File preview view for images and videos
//

import SwiftUI
import UIKit

struct FilePreviewView: View {
    let file: FileItem
    let theme: Theme
    
    @Environment(\.dismiss) var dismiss
    @State private var imageData: Data?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(theme.accentColor)
                        
                        Text(error)
                            .font(.system(size: 16))
                            .foregroundColor(theme.textColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    ScrollView {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Text("Preview not available")
                        .font(.system(size: 16))
                        .foregroundColor(theme.textColor.opacity(0.6))
                }
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
            .onAppear {
                loadPreview()
            }
        }
        .applyTheme(theme)
    }
    
    private func loadPreview() {
        Task {
            do {
                let data = try await NetworkService.shared.downloadFile(path: file.relativePath)
                await MainActor.run {
                    self.imageData = data
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
        theme: Theme.retro
    )
}

