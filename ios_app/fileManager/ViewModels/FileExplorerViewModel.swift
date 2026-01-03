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
    
    func downloadFile(file: FileItem) async {
        do {
            let data = try await networkService.downloadFile(path: file.relativePath)
            // Save file to device
            await saveFileToDevice(data: data, fileName: file.name)
        } catch {
            errorMessage = "Failed to download file: \(error.localizedDescription)"
        }
    }
    
    private func saveFileToDevice(data: Data, fileName: String) async {
        // Save file to Documents directory
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            await MainActor.run {
                // Show success message or use UIActivityViewController to share
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }
}

