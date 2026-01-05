//
//  FileItem.swift
//  fileManager
//
//  Model representing a file or directory item
//

import Foundation

struct FileItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let path: String
    let relativePath: String
    let isDirectory: Bool
    let size: String
    let modified: String
    let isImage: Bool
    let isVideo: Bool
    let isMedia: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case relativePath = "relative_path"
        case isDirectory = "is_dir"
        case size
        case modified
        case isImage = "is_image"
        case isVideo = "is_video"
        case isMedia = "is_media"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        relativePath = try container.decodeIfPresent(String.self, forKey: .relativePath) ?? ""
        path = relativePath.isEmpty ? name : relativePath
        isDirectory = try container.decodeIfPresent(Bool.self, forKey: .isDirectory) ?? false
        size = try container.decodeIfPresent(String.self, forKey: .size) ?? "-"
        modified = try container.decodeIfPresent(String.self, forKey: .modified) ?? ""
        isImage = try container.decodeIfPresent(Bool.self, forKey: .isImage) ?? false
        isVideo = try container.decodeIfPresent(Bool.self, forKey: .isVideo) ?? false
        isMedia = try container.decodeIfPresent(Bool.self, forKey: .isMedia) ?? false
        id = relativePath.isEmpty ? name : relativePath
    }
    
    // Manual initializer for previews
    init(id: String, name: String, path: String, relativePath: String, isDirectory: Bool, size: String, modified: String, isImage: Bool, isVideo: Bool, isMedia: Bool) {
        self.id = id
        self.name = name
        self.path = path
        self.relativePath = relativePath
        self.isDirectory = isDirectory
        self.size = size
        self.modified = modified
        self.isImage = isImage
        self.isVideo = isVideo
        self.isMedia = isMedia
    }
}

struct FileListResponse: Codable {
    let items: [FileItem]
    let currentPath: String
    let breadcrumbs: [Breadcrumb]
    
    enum CodingKeys: String, CodingKey {
        case items
        case currentPath = "current_path"
        case breadcrumbs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([FileItem].self, forKey: .items) ?? []
        currentPath = try container.decodeIfPresent(String.self, forKey: .currentPath) ?? ""
        breadcrumbs = try container.decodeIfPresent([Breadcrumb].self, forKey: .breadcrumbs) ?? []
    }
}

struct Breadcrumb: Codable, Identifiable {
    let id: String
    let name: String
    let path: String
    
    init(name: String, path: String) {
        self.name = name
        self.path = path
        self.id = path
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        path = try container.decodeIfPresent(String.self, forKey: .path) ?? ""
        id = path.isEmpty ? (name.isEmpty ? "root" : name) : path
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case path
    }
}

