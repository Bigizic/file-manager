//
//  NoteDetailViewModel.swift
//  fileManager
//
//  ViewModel for note detail
//

import Foundation

@MainActor
class NoteDetailViewModel: ObservableObject {
    private let networkService = NetworkService.shared
    
    func updateNote(id: Int, title: String, content: String) async throws {
        _ = try await networkService.updateNote(id: id, title: title, content: content)
    }
}

