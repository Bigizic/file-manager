//
//  ServerSettings.swift
//  fileManager
//
//  Model for server settings and configuration
//

import Foundation

struct ServerSettings: Codable {
    let serverURL: String
    let serverName: String?
    let version: String?
    let isConnected: Bool
    let lastConnected: Date?
    
    init(serverURL: String, serverName: String? = nil, version: String? = nil, isConnected: Bool = false, lastConnected: Date? = nil) {
        self.serverURL = serverURL
        self.serverName = serverName
        self.version = version
        self.isConnected = isConnected
        self.lastConnected = lastConnected
    }
}

struct ServerConnectionResponse: Codable {
    let success: Bool
    let message: String?
    let serverInfo: ServerInfo?
}

struct ServerInfo: Codable {
    let name: String?
    let version: String?
    let features: [String]?
}

