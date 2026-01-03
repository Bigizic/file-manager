//
//  ServerConnectionViewModel.swift
//  fileManager
//
//  ViewModel for server connection management
//

import Foundation
import SwiftUI

@MainActor
class ServerConnectionViewModel: ObservableObject {
    @Published var isConnecting: Bool = false
    @Published var connectionError: String?
    @Published var currentServer: ServerSettings?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    private let networkService = NetworkService.shared
    private let serverSettingsKey = "currentServerSettings"
    
    init() {
        loadSavedServer()
    }
    
    func loadSavedServer() {
        if let data = UserDefaults.standard.data(forKey: serverSettingsKey),
           let server = try? JSONDecoder().decode(ServerSettings.self, from: data) {
            self.currentServer = server
            if server.isConnected {
                self.connectionStatus = .connected
                // Update NetworkService with saved URL
                NetworkService.shared.setBaseURL(server.serverURL)
            }
        }
    }
    
    func connectToServer(url: String) async {
        isConnecting = true
        connectionError = nil
        connectionStatus = .connecting
        
        // Normalize URL
        let normalizedURL = normalizeURL(url)
        
        // Test connection
        do {
            let isConnected = try await networkService.testConnection(to: normalizedURL)
            
            if isConnected {
                // Fetch server info
                let serverInfo = try? await networkService.fetchServerInfo(from: normalizedURL)
                
                let server = ServerSettings(
                    serverURL: normalizedURL,
                    serverName: serverInfo?.name,
                    version: serverInfo?.version,
                    isConnected: true,
                    lastConnected: Date()
                )
                
                // Save to UserDefaults
                if let encoded = try? JSONEncoder().encode(server) {
                    UserDefaults.standard.set(encoded, forKey: serverSettingsKey)
                }
                
                // Update NetworkService
                NetworkService.shared.setBaseURL(normalizedURL)
                
                self.currentServer = server
                self.connectionStatus = .connected
                self.connectionError = nil
            } else {
                throw NetworkError.invalidResponse
            }
        } catch {
            self.connectionError = error.localizedDescription
            self.connectionStatus = .error(error.localizedDescription)
        }
        
        isConnecting = false
    }
    
    func disconnect() {
        UserDefaults.standard.removeObject(forKey: serverSettingsKey)
        self.currentServer = nil
        self.connectionStatus = .disconnected
        NetworkService.shared.setBaseURL(nil)
    }
    
    private func normalizeURL(_ url: String) -> String {
        var normalized = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove trailing slash
        if normalized.hasSuffix("/") {
            normalized = String(normalized.dropLast())
        }
        
        // Add http:// if no scheme provided
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "http://\(normalized)"
        }
        
        return normalized
    }
}

