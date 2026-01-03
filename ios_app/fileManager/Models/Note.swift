//
//  Note.swift
//  fileManager
//
//  Model representing a note
//

import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let content: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: Int, title: String, content: String, createdAt: String, updatedAt: String) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct NoteListResponse: Codable {
    let notes: [Note]
}

struct NoteResponse: Codable {
    let note: Note
}

struct NoteCreateRequest: Codable {
    let title: String
    let content: String
}

struct NoteUpdateRequest: Codable {
    let title: String
    let content: String
}

