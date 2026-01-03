//
//  NotesListView.swift
//  fileManager
//
//  Notes list view
//

import SwiftUI

struct NotesListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = NotesListViewModel()
    @State private var showCreateNote = false
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error, theme: themeManager.currentTheme) {
                        viewModel.loadNotes()
                    }
                } else if viewModel.notes.isEmpty {
                    EmptyNotesView(theme: themeManager.currentTheme) {
                        showCreateNote = true
                    }
                } else {
                    List {
                        ForEach(viewModel.notes) { note in
                            NoteCardView(note: note, theme: themeManager.currentTheme) {
                                selectedNote = note
                            }
                            .listRowBackground(themeManager.currentTheme.cardBackgroundColor)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let note = viewModel.notes[index]
                                viewModel.deleteNote(note)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(themeManager.currentTheme.backgroundColor)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateNote = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadNotes()
            }
            .sheet(isPresented: $showCreateNote) {
                NoteEditView(note: nil, theme: themeManager.currentTheme) {
                    viewModel.loadNotes()
                }
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note, theme: themeManager.currentTheme) {
                    viewModel.loadNotes()
                }
            }
        }
        .applyTheme(themeManager.currentTheme)
    }
}

struct NoteCardView: View {
    let note: Note
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(note.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor.opacity(0.7))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Text(formatDate(note.updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColor.opacity(0.5))
                    
                    Spacer()
                }
            }
            .padding()
            .background(theme.cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.cardBorderColor, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple date formatting - you might want to use DateFormatter for better formatting
        return dateString
    }
}

struct EmptyNotesView: View {
    let theme: Theme
    let onCreateNote: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(theme.textColor.opacity(0.3))
            
            Text("No Notes")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text("Create your first note to get started")
                .font(.system(size: 14))
                .foregroundColor(theme.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button("Create Note", action: onCreateNote)
                .buttonStyle(PrimaryButtonStyle(theme: theme))
        }
        .padding()
    }
}

#Preview {
    NotesListView()
        .environmentObject(ThemeManager.shared)
}

