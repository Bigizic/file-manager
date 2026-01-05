//
//  FileSaveCoordinator.swift
//  fileManager
//
//  Coordinator for saving files using document picker
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct FileSaveCoordinator: UIViewControllerRepresentable {
    let data: Data
    let fileName: String
    let onComplete: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create a temporary file to save
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
        } catch {
            onComplete(false)
            return UIDocumentPickerViewController(forOpeningContentTypes: [])
        }
        
        // Create document picker in export mode
        let picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, fileName: fileName)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onComplete: (Bool) -> Void
        let fileName: String
        
        init(onComplete: @escaping (Bool) -> Void, fileName: String) {
            self.onComplete = onComplete
            self.fileName = fileName
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // User selected a location - file is automatically saved
            onComplete(true)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled
            onComplete(false)
        }
    }
}

