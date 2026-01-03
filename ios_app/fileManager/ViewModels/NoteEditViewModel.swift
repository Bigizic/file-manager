//
//  NoteEditViewModel.swift
//  fileManager
//
//  ViewModel for note editing
//

import Foundation

@MainActor
class NoteEditViewModel: ObservableObject {
    private let networkService = NetworkService.shared
    
    func createNote(title: String, content: String) async throws {
        _ = try await networkService.createNote(title: title, content: content)
    }
    
    func updateNote(id: Int, title: String, content: String) async throws {
        _ = try await networkService.updateNote(id: id, title: title, content: content)
    }
}

