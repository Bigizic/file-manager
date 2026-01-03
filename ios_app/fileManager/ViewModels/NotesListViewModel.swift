//
//  NotesListViewModel.swift
//  fileManager
//
//  ViewModel for notes list
//

import Foundation
import SwiftUI

@MainActor
class NotesListViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    
    func loadNotes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedNotes = try await networkService.fetchNotes()
                self.notes = fetchedNotes
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteNote(_ note: Note) {
        Task {
            do {
                try await networkService.deleteNote(id: note.id)
                loadNotes()
            } catch {
                errorMessage = "Failed to delete note: \(error.localizedDescription)"
            }
        }
    }
}

