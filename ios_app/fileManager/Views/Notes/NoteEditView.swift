//
//  NoteEditView.swift
//  fileManager
//
//  Note create/edit screen
//

import SwiftUI

struct NoteEditView: View {
    let note: Note?
    let theme: Theme
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var content: String
    @StateObject private var viewModel = NoteEditViewModel()
    
    init(note: Note?, theme: Theme, onSave: @escaping () -> Void) {
        self.note = note
        self.theme = theme
        self.onSave = onSave
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Title")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        TextField("Enter note title", text: $title)
                            .textFieldStyle(ThemedTextFieldStyle(theme: theme))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 300)
                            .padding(8)
                            .background(theme.surfaceColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.borderColor, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .background(theme.backgroundColor)
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(theme.accentColor)
                    .disabled(title.isEmpty)
                }
            }
        }
        .applyTheme(theme)
    }
    
    private func saveNote() {
        Task {
            do {
                if let note = note {
                    try await viewModel.updateNote(
                        id: note.id,
                        title: title,
                        content: content
                    )
                } else {
                    try await viewModel.createNote(
                        title: title,
                        content: content
                    )
                }
                onSave()
                dismiss()
            } catch {
                // Handle error
            }
        }
    }
}

#Preview {
    NoteEditView(note: nil, theme: Theme.retro, onSave: {})
}

