# File Manager iOS App

A native iOS application that mimics the web-based file manager, built with SwiftUI for iOS 18+.

## Features

- **File Browsing**: Browse and navigate through files and directories
- **Theme System**: Four themes available:
  - Retro (Default)
  - Robotic
  - Cyberpunk
  - Modern SaaS
- **Notes Management**: Create, edit, and delete notes
- **File Preview**: Preview images and videos
- **File Download**: Download files to device

## Project Structure

```
fileManager/
├── App/
│   ├── fileManagerApp.swift      # App entry point
│   └── ContentView.swift          # Main navigation
├── Models/
│   ├── AppState.swift            # Global app state
│   ├── FileItem.swift            # File model
│   ├── Note.swift                 # Note model
│   └── Theme.swift                # Theme definitions
├── Views/
│   ├── Home/
│   │   └── HomeView.swift         # Home screen with theme selector
│   ├── FileExplorer/
│   │   ├── FileExplorerView.swift # File browser
│   │   └── FilePreviewView.swift  # File preview
│   └── Notes/
│       ├── NotesListView.swift   # Notes list
│       ├── NoteDetailView.swift  # Note detail/view
│       └── NoteEditView.swift    # Note create/edit
├── ViewModels/
│   ├── FileExplorerViewModel.swift
│   ├── NotesListViewModel.swift
│   ├── NoteDetailViewModel.swift
│   └── NoteEditViewModel.swift
├── Services/
│   └── NetworkService.swift      # API communication
├── Managers/
│   └── ThemeManager.swift        # Theme management
├── Utilities/
│   └── ThemeExtensions.swift     # Theme utilities
└── Info.plist                    # App configuration
```

## Configuration

The app uses a `.xcconfig` file for configuration. Edit `Config.xcconfig` to change the backend URL:

```
BACKEND_BASE_URL = http://your-server-url:5000
```

## Setup Instructions

1. Open the project in Xcode (iOS 18+ required)
2. Update `Config.xcconfig` with your backend server URL
3. Build and run the app

## Architecture

- **MVVM Pattern**: ViewModels handle business logic
- **SwiftUI**: Modern declarative UI framework
- **Async/Await**: Modern concurrency for network calls
- **Environment Objects**: Shared state management
- **Theming**: Centralized theme system

## Requirements

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+

## Backend Integration

The app expects the backend to provide:
- File listing API at `/explorer` or `/explorer/{path}`
- File download at `/download/{path}`
- Notes API at `/api/notes`
- Notes CRUD operations

## Notes

- The app uses UserDefaults for theme persistence
- Network errors are displayed to the user
- File downloads are saved to the Documents directory
- Theme changes apply immediately across all views

