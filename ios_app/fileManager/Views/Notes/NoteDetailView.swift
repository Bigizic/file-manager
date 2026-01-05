//
//  NoteDetailView.swift
//  fileManager
//
//  Note detail/view screen
//

import SwiftUI

struct NoteDetailView: View {
    let note: Note
    let onUpdate: () -> Void
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @StateObject private var viewModel = NoteDetailViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    init(note: Note, onUpdate: @escaping () -> Void) {
        self.note = note
        self.onUpdate = onUpdate
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Title")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("Title", text: $editedTitle)
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
                            
                            TextEditor(text: $editedContent)
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
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(note.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Divider()
                                .background(Color(UIColor.separator))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(note.content)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 1)
                            )
                            
                            HStack {
                                Text("Updated: \(formatDate(note.updatedAt))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle(isEditing ? "Edit Note" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
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
                    } else {
                        Button("Edit") {
                            isEditing = true
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
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                            editedTitle = note.title
                            editedContent = note.content
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
                }
            }
        }
    }
    
    private func saveNote() {
        Task {
            do {
                try await viewModel.updateNote(
                    id: note.id,
                    title: editedTitle,
                    content: editedContent
                )
                isEditing = false
                onUpdate()
            } catch {
                // Handle error
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        return dateString
    }
}

#Preview {
    NoteDetailView(
        note: Note(
            id: 1,
            title: "Sample Note",
            content: "This is a sample note content.",
            createdAt: "2024-01-01",
            updatedAt: "2024-01-01"
        ),
        onUpdate: {}
    )
}
