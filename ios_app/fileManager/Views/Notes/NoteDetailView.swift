//
//  NoteDetailView.swift
//  fileManager
//
//  Note detail/view screen
//

import SwiftUI

struct NoteDetailView: View {
    let note: Note
    let theme: Theme
    let onUpdate: () -> Void
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @StateObject private var viewModel = NoteDetailViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    init(note: Note, theme: Theme, onUpdate: @escaping () -> Void) {
        self.note = note
        self.theme = theme
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
                                .foregroundColor(theme.textColor)
                            
                            TextField("Title", text: $editedTitle)
                                .padding()
                                .background(textFieldBackground)
                                .foregroundColor(textFieldTextColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.borderColor, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Content")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textColor)
                            
                            TextEditor(text: $editedContent)
                                .frame(minHeight: 300)
                                .padding(8)
                                .background(textFieldBackground)
                                .foregroundColor(textFieldTextColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.borderColor, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(note.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(theme.textColor)
                            
                            Divider()
                                .background(theme.borderColor)
                            
                            Text(note.content)
                                .font(.system(size: 16))
                                .foregroundColor(theme.textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Text("Updated: \(formatDate(note.updatedAt))")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textColor.opacity(0.6))
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(theme.backgroundColor)
            .navigationTitle(isEditing ? "Edit Note" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveNote()
                        }
                        .foregroundColor(toolbarForegroundColorAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(toolbarGlassBackground)
                        .clipShape(Capsule())
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                        .foregroundColor(editButtonForeground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(editButtonBackground)
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
                        .foregroundColor(toolbarForegroundColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(toolbarGlassBackground)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .applyTheme(theme)
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
    
    // MARK: - Theming helpers
    private var isDarkTheme: Bool {
        theme.colorScheme == .dark
    }
    
    private var textFieldBackground: Color {
        isDarkTheme ? theme.surfaceColor : .white
    }
    
    private var textFieldTextColor: Color {
        isDarkTheme ? theme.textColor : .black
    }
    
    private var toolbarGlassBackground: some View {
        let base: Color
        if theme.id == .retro {
            base = isDarkTheme ? .black.opacity(0.8) : .white.opacity(0.8)
        } else {
            base = .clear
        }
        return base.background(.ultraThinMaterial)
    }
    
    private var toolbarForegroundColor: Color {
        if theme.id == .retro {
            return isDarkTheme ? .white : .black
        }
        return isDarkTheme ? .white : .black
    }
    
    private var toolbarForegroundColorAccent: Color {
        if theme.id == .retro {
            return isDarkTheme ? .white : .black
        }
        return isDarkTheme ? .white : .black
    }
    
    private var editButtonForeground: Color {
        if theme.id == .retro {
            return isDarkTheme ? .white : .black
        }
        return isDarkTheme ? .white : .black
    }
    
    private var editButtonBackground: some View {
        let base: Color
        if theme.id == .retro {
            base = isDarkTheme ? .black.opacity(0.8) : .white.opacity(0.8)
        } else {
            base = .clear
        }
        return base.background(.ultraThinMaterial)
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
        theme: Theme.retro,
        onUpdate: {}
    )
}

