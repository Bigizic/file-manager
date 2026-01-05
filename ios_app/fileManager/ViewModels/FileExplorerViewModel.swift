//
//  FileExplorerViewModel.swift
//  fileManager
//
//  ViewModel for file explorer
//

import Foundation
import SwiftUI

@MainActor
class FileExplorerViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var breadcrumbs: [Breadcrumb] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var clipboardPath: String?
    @Published var clipboardOperation: String? // "copy" or "cut"
    @Published var downloadSuccessMessage: String?
    
    private let networkService = NetworkService.shared
    
    func loadFiles(path: String = "") {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await networkService.fetchFileList(path: path)
                self.files = response.items
                self.breadcrumbs = response.breadcrumbs
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func downloadFile(file: FileItem, relativePath: String) async {
        do {
            let data = try await networkService.downloadFile(path: file.relativePath)
            // Save file to device with directory structure
            await saveFileToDevice(data: data, file: file, relativePath: relativePath)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to download file: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteFile(_ file: FileItem, currentPath: String) async {
        do {
            try await networkService.deleteFile(path: file.relativePath)
            loadFiles(path: currentPath)
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
    
    func renameFile(_ file: FileItem, newName: String, currentPath: String) async {
        do {
            try await networkService.renameFile(path: file.relativePath, newName: newName)
            loadFiles(path: currentPath)
        } catch {
            errorMessage = "Failed to rename: \(error.localizedDescription)"
        }
    }
    
    func copyFile(_ file: FileItem) async {
        do {
            try await networkService.copyFile(path: file.relativePath)
            clipboardPath = file.relativePath
            clipboardOperation = "copy"
        } catch {
            errorMessage = "Failed to copy: \(error.localizedDescription)"
        }
    }
    
    func cutFile(_ file: FileItem) async {
        do {
            try await networkService.cutFile(path: file.relativePath)
            clipboardPath = file.relativePath
            clipboardOperation = "cut"
        } catch {
            errorMessage = "Failed to cut: \(error.localizedDescription)"
        }
    }
    
    func pasteFile(targetDirectory: String) async {
        guard let sourcePath = clipboardPath, let operation = clipboardOperation else {
            errorMessage = "No file in clipboard"
            return
        }
        
        // Clear clipboard immediately (even if paste fails)
        clipboardPath = nil
        clipboardOperation = nil
        
        do {
            try await networkService.pasteFile(sourcePath: sourcePath, targetDirectory: targetDirectory, operation: operation)
            loadFiles(path: targetDirectory)
        } catch {
            errorMessage = "Failed to paste: \(error.localizedDescription)"
            // Clipboard already cleared above
        }
    }
    
    func moveFile(_ file: FileItem, targetDirectory: String, currentPath: String) async {
        do {
            try await networkService.moveFile(path: file.relativePath, targetDirectory: targetDirectory)
            loadFiles(path: currentPath)
        } catch {
            errorMessage = "Failed to move: \(error.localizedDescription)"
        }
    }
    
    func createFile(fileName: String, content: String = "", targetDirectory: String = "") async {
        do {
            try await networkService.createFile(fileName: fileName, content: content, targetDirectory: targetDirectory)
            loadFiles(path: targetDirectory)
        } catch {
            errorMessage = "Failed to create file: \(error.localizedDescription)"
        }
    }
    
    func createFolder(folderName: String, targetDirectory: String = "") async {
        do {
            try await networkService.createFolder(folderName: folderName, targetDirectory: targetDirectory)
            loadFiles(path: targetDirectory)
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }
    
    func uploadFile(fileData: Data, fileName: String, targetDirectory: String = "") async {
        do {
            try await networkService.uploadFile(fileData: fileData, fileName: fileName, targetDirectory: targetDirectory)
            loadFiles(path: targetDirectory)
        } catch {
            errorMessage = "Failed to upload file: \(error.localizedDescription)"
        }
    }
    
    private func saveFileToDevice(data: Data, file: FileItem, relativePath: String) async {
        // Get server name from saved settings
        let serverName: String
        let serverSettingsKey = "currentServerSettings"
        if let serverData = UserDefaults.standard.data(forKey: serverSettingsKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            if let server = try? decoder.decode(ServerSettings.self, from: serverData) {
                if let name = server.serverName, !name.isEmpty {
                    serverName = name
                } else if let url = URL(string: server.serverURL), let host = url.host {
                    serverName = host
                } else {
                    serverName = "Server"
                }
            } else {
                // Try iso8601 as fallback
                decoder.dateDecodingStrategy = .iso8601
                if let server = try? decoder.decode(ServerSettings.self, from: serverData) {
                    if let name = server.serverName, !name.isEmpty {
                        serverName = name
                    } else if let url = URL(string: server.serverURL), let host = url.host {
                        serverName = host
                    } else {
                        serverName = "Server"
                    }
                } else {
                    serverName = "Server"
                }
            }
        } else {
            serverName = "Server"
        }
        
        // Use Documents directory which is accessible in Files app
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            await MainActor.run {
                errorMessage = "Failed to access Documents directory"
            }
            return
        }
        
        // Create directory structure: Documents/FileManager/ServerName/relativePath
        let fileManagerDir = documentsDirectory.appendingPathComponent("FileManager", isDirectory: true)
        let serverDir = fileManagerDir.appendingPathComponent(serverName, isDirectory: true)
        
        // Build the full path preserving the relative path structure
        // If relativePath is empty, we're at root, so just save to serverDir
        // Otherwise, preserve the full path structure
        var targetDir = serverDir
        
        if !relativePath.isEmpty {
            let pathComponents = relativePath.components(separatedBy: "/").filter { !$0.isEmpty }
            for component in pathComponents {
                targetDir = targetDir.appendingPathComponent(component, isDirectory: true)
            }
        }
        
        // Create directories if they don't exist
        do {
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create directory: \(error.localizedDescription)"
            }
            return
        }
        
        // Save file
        var fileURL = targetDir.appendingPathComponent(file.name)
        
        do {
            try data.write(to: fileURL)
            
            // Mark the file as not being backed up to iCloud (optional)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try? fileURL.setResourceValues(resourceValues)
            
            await MainActor.run {
                // File saved successfully - show success message
                let pathDisplay: String
                if relativePath.isEmpty {
                    pathDisplay = "FileManager/\(serverName)/\(file.name)"
                } else {
                    pathDisplay = "FileManager/\(serverName)/\(relativePath)/\(file.name)"
                }
                downloadSuccessMessage = "File saved to Files app:\n\(pathDisplay)"
                print("File saved successfully to: \(fileURL.path)")
                
                // Clear success message after 3 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        downloadSuccessMessage = nil
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }
}
