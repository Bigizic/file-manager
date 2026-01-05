//
//  NoteEditView.swift
//  fileManager
//
//  Note create/edit screen
//

import SwiftUI

struct NoteEditView: View {
    let note: Note?
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var title: String
    @State private var content: String
    @StateObject private var viewModel = NoteEditViewModel()
    
    init(note: Note?, onSave: @escaping () -> Void) {
        self.note = note
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
                            .foregroundColor(.primary)
                        
                        TextField("Enter note title", text: $title)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(UIColor.separator), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 300)
                            .padding(8)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(UIColor.separator), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                            .background(.ultraThinMaterial)
                    )
                    .clipShape(Capsule())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                            .background(.ultraThinMaterial)
                    )
                    .clipShape(Capsule())
                    .disabled(title.isEmpty)
                }
            }
        }
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
    NoteEditView(note: nil, onSave: {})
}
