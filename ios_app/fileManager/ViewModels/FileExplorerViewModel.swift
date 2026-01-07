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
    
    let networkService = NetworkService.shared
    var notificationManager: NotificationManager?
    
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
                let errorMsg = extractErrorMessage(from: error)
                self.errorMessage = errorMsg
                self.isLoading = false
                // Show notification for load errors too
                notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
            }
        }
    }
    
    func downloadFile(file: FileItem, relativePath: String) async {
        // Get location string for notification
        let location = relativePath.isEmpty ? "Root" : relativePath
        
        // Show initial download notification
        await MainActor.run {
            IOSNotificationManager.shared.showDownloadProgressNotification(
                fileName: file.name,
                location: location,
                progress: 0.0
            )
        }
        
        do {
            // Download with progress tracking
            let data = try await networkService.downloadFileWithProgress(path: file.relativePath) { progress in
                Task { @MainActor in
                    IOSNotificationManager.shared.showDownloadProgressNotification(
                        fileName: file.name,
                        location: location,
                        progress: progress
                    )
                }
            }
            
            // Save file to device with directory structure
            await saveFileToDevice(data: data, file: file, relativePath: relativePath)
        } catch {
            await MainActor.run {
                let errorMsg = extractErrorMessage(from: error)
                errorMessage = errorMsg
                IOSNotificationManager.shared.showDownloadErrorNotification(
                    fileName: file.name,
                    error: errorMsg
                )
            }
        }
    }
    
    func deleteFile(_ file: FileItem, currentPath: String) async {
        do {
            try await networkService.deleteFile(path: file.relativePath)
            loadFiles(path: currentPath)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func renameFile(_ file: FileItem, newName: String, currentPath: String) async {
        do {
            try await networkService.renameFile(path: file.relativePath, newName: newName)
            loadFiles(path: currentPath)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func copyFile(_ file: FileItem) async {
        do {
            try await networkService.copyFile(path: file.relativePath)
            clipboardPath = file.relativePath
            clipboardOperation = "copy"
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func cutFile(_ file: FileItem) async {
        do {
            try await networkService.cutFile(path: file.relativePath)
            clipboardPath = file.relativePath
            clipboardOperation = "cut"
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func pasteFile(targetDirectory: String) async {
        guard let sourcePath = clipboardPath, let operation = clipboardOperation else {
            let message = "No file in clipboard"
            errorMessage = message
            notificationManager?.show(NotificationItem(message: message, type: .warning))
            return
        }
        
        // Clear clipboard immediately (even if paste fails)
        clipboardPath = nil
        clipboardOperation = nil
        
        do {
            try await networkService.pasteFile(sourcePath: sourcePath, targetDirectory: targetDirectory, operation: operation)
            loadFiles(path: targetDirectory)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
            // Clipboard already cleared above
        }
    }
    
    private func extractErrorMessage(from error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .httpError(let code, let message):
                if let message = message {
                    return message
                }
                return "HTTP Error \(code)"
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .decodingError(let decodingError):
                return "Failed to parse response: \(decodingError.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
    
    func moveFile(_ file: FileItem, targetDirectory: String, currentPath: String) async {
        do {
            try await networkService.moveFile(path: file.relativePath, targetDirectory: targetDirectory)
            loadFiles(path: currentPath)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func createFile(fileName: String, content: String = "", targetDirectory: String = "") async {
        do {
            try await networkService.createFile(fileName: fileName, content: content, targetDirectory: targetDirectory)
            loadFiles(path: targetDirectory)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func createFolder(folderName: String, targetDirectory: String = "") async {
        do {
            try await networkService.createFolder(folderName: folderName, targetDirectory: targetDirectory)
            loadFiles(path: targetDirectory)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func uploadFile(fileData: Data, fileName: String, targetDirectory: String = "") async {
        do {
            try await networkService.uploadFile(fileData: fileData, fileName: fileName, targetDirectory: targetDirectory)
            loadFiles(path: targetDirectory)
        } catch {
            let errorMsg = extractErrorMessage(from: error)
            errorMessage = errorMsg
            notificationManager?.show(NotificationItem(message: errorMsg, type: .error))
        }
    }
    
    func loadAllDirectories() async -> [FileItem] {
        var allDirectories: [FileItem] = []
        
        func loadDirectoriesRecursively(path: String) async {
            do {
                let response = try await networkService.fetchFileList(path: path)
                let dirs = response.items.filter { $0.isDirectory }
                allDirectories.append(contentsOf: dirs)
                
                // Recursively load subdirectories
                for dir in dirs {
                    await loadDirectoriesRecursively(path: dir.relativePath)
                }
            } catch {
                // Silently skip directories we can't access
            }
        }
        
        await loadDirectoriesRecursively(path: "")
        return allDirectories
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
                // File saved successfully - show iOS notification
                let directoryPath: String
                if relativePath.isEmpty {
                    directoryPath = "FileManager/\(serverName)"
                } else {
                    directoryPath = "FileManager/\(serverName)/\(relativePath)"
                }
                
                IOSNotificationManager.shared.showDownloadSuccessNotification(
                    fileName: file.name,
                    directory: directoryPath
                )
                print("File saved successfully to: \(fileURL.path)")
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }
}
