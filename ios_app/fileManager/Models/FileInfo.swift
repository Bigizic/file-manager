//
//  FileInfo.swift
//  fileManager
//
//  File information model
//

import Foundation

struct FileInfo: Codable {
    let name: String
    let fullPath: String
    let relativePath: String
    let isDirectory: Bool
    let isFile: Bool
    let sizeFormatted: String?
    let sizeBytes: Int?
    let modified: String
    let created: String?
    let accessed: String?
    let mimeType: String?
    let `extension`: String?
    let isReadable: Bool?
    let isWritable: Bool?
    let isExecutable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case fullPath = "full_path"
        case relativePath = "relative_path"
        case isDirectory = "is_directory"
        case isFile = "is_file"
        case sizeFormatted = "size_formatted"
        case sizeBytes = "size_bytes"
        case modified
        case created
        case accessed
        case mimeType = "mime_type"
        case `extension`
        case isReadable = "is_readable"
        case isWritable = "is_writable"
        case isExecutable = "is_executable"
    }
}

struct FileInfoResponse: Codable {
    let success: Bool
    let info: FileInfo
}

