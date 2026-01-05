//
//  NotesListView.swift
//  fileManager
//
//  Notes list view
//

import SwiftUI

struct NotesListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = NotesListViewModel()
    @State private var showCreateNote = false
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.loadNotes()
                    }
                } else if viewModel.notes.isEmpty {
                    EmptyNotesView {
                        showCreateNote = true
                    }
                } else {
                    List {
                        ForEach(viewModel.notes) { note in
                            NoteCardView(note: note) {
                                selectedNote = note
                            }
                            .listRowBackground(Color.clear)
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
                    .background(Color(UIColor.systemBackground))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateNote = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(8)
                            .background(
                                (colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                                    .background(.ultraThinMaterial)
                            )
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                viewModel.loadNotes()
            }
            .sheet(isPresented: $showCreateNote) {
                NoteEditView(note: nil) {
                    viewModel.loadNotes()
                }
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note) {
                    viewModel.loadNotes()
                }
            }
        }
    }
}

struct NoteCardView: View {
    let note: Note
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(note.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Text(formatDate(note.updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        return dateString
    }
}

struct EmptyNotesView: View {
    let onCreateNote: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Notes")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Create your first note to get started")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Note", action: onCreateNote)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NotesListView()
}
