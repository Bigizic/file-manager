//
//  FileInfoView.swift
//  fileManager
//
//  File information view
//

import SwiftUI
import Foundation

struct FileInfoView: View {
    let file: FileItem
    @Environment(\.dismiss) var dismiss
    @State private var fileInfo: FileInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading file information...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("OK") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let info = fileInfo {
                    Form {
                        Section("Basic Information") {
                            InfoRow(label: "Name", value: info.name)
                            InfoRow(label: "Type", value: info.isDirectory ? "Folder" : "File")
                            if let size = info.sizeFormatted {
                                InfoRow(label: "Size", value: size)
                            }
                            if let ext = info.extension, !ext.isEmpty {
                                InfoRow(label: "Extension", value: ext)
                            }
                            if let mime = info.mimeType, mime != "unknown" {
                                InfoRow(label: "MIME Type", value: mime)
                            }
                        }
                        
                        Section("Location") {
                            InfoRow(label: "Path", value: info.relativePath)
                        }
                        
                        Section("Timestamps") {
                            InfoRow(label: "Modified", value: info.modified)
                            if let created = info.created {
                                InfoRow(label: "Created", value: created)
                            }
                            if let accessed = info.accessed {
                                InfoRow(label: "Accessed", value: accessed)
                            }
                        }
                        
                        Section("Permissions") {
                            if let readable = info.isReadable {
                                InfoRow(label: "Readable", value: readable ? "Yes" : "No")
                            }
                            if let writable = info.isWritable {
                                InfoRow(label: "Writable", value: writable ? "Yes" : "No")
                            }
                            if let executable = info.isExecutable {
                                InfoRow(label: "Executable", value: executable ? "Yes" : "No")
                            }
                        }
                    }
                }
            }
            .navigationTitle("File Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task(id: file.id) {
                // Reset state when file changes
                fileInfo = nil
                errorMessage = nil
                isLoading = true
                loadFileInfo()
            }
        }
    }
    
    private func loadFileInfo() {
        Task {
            do {
                let info = try await NetworkService.shared.fetchFileInfo(path: file.relativePath)
                await MainActor.run {
                    self.fileInfo = info
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Extract better error message
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(let code, let message):
                            self.errorMessage = message ?? "HTTP Error \(code)"
                        case .invalidURL:
                            self.errorMessage = "Invalid URL"
                        case .invalidResponse:
                            self.errorMessage = "Invalid response from server"
                        case .decodingError(let decodingError):
                            self.errorMessage = "Failed to parse response: \(decodingError.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    FileInfoView(
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
        )
    )
}

