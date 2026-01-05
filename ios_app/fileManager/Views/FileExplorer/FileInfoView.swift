//
//  FileInfoView.swift
//  fileManager
//
//  File information view
//

import SwiftUI

struct FileInfo: Codable {
    let name: String
    let fullPath: String
    let relativePath: String
    let isDirectory: Bool
    let isFile: Bool
    let sizeFormatted: String?
    let sizeBytes: Int?
    let modified: String
    let created: String?
    let accessed: String?
    let mimeType: String?
    let extension: String?
    let isReadable: Bool?
    let isWritable: Bool?
    let isExecutable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case fullPath = "full_path"
        case relativePath = "relative_path"
        case isDirectory = "is_directory"
        case isFile = "is_file"
        case sizeFormatted = "size_formatted"
        case sizeBytes = "size_bytes"
        case modified
        case created
        case accessed
        case mimeType = "mime_type"
        case `extension`
        case isReadable = "is_readable"
        case isWritable = "is_writable"
        case isExecutable = "is_executable"
    }
}

struct FileInfoResponse: Codable {
    let success: Bool
    let info: FileInfo
}

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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        
                        Text(error)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
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
            .onAppear {
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
                    self.errorMessage = error.localizedDescription
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

