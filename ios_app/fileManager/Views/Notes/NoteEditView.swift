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
                        
                        TextEditor(text: $content)
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
                    .foregroundColor(toolbarForegroundColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(toolbarGlassBackground)
                    .clipShape(Capsule())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(toolbarForegroundColorAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(toolbarGlassBackground)
                    .clipShape(Capsule())
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
    
    // MARK: - Theming helpers
    private var isDarkTextArea: Bool {
        // Retro uses white text areas even in dark; only robotic/cyberpunk stay dark
        theme.id == .robotic || theme.id == .cyberpunk
    }
    
    private var textFieldBackground: Color {
        isDarkTextArea ? theme.surfaceColor : .white
    }
    
    private var textFieldTextColor: Color {
        isDarkTextArea ? theme.textColor : .black
    }
    
    private var toolbarGlassBackground: some View {
        Color.clear.background(.ultraThinMaterial)
    }
    
    private var toolbarForegroundColor: Color {
        switch theme.id {
        case .retro:
            return .black
        case .saas:
            return theme.textColor
        default:
            return theme.textColor
        }
    }
    
    private var toolbarForegroundColorAccent: Color {
        switch theme.id {
        case .retro:
            return .black
        case .saas:
            return theme.accentColor
        default:
            return theme.accentColor
        }
    }
}

#Preview {
    NoteEditView(note: nil, theme: Theme.retro, onSave: {})
}

