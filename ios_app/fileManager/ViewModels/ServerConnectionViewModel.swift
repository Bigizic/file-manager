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
    
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    private let networkService = NetworkService.shared
    private let serverSettingsKey = "currentServerSettings"
    
    init() {
        loadSavedServer()
    }
    
    func loadSavedServer() {
        guard let data = UserDefaults.standard.data(forKey: serverSettingsKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        // Try secondsSince1970 first (default), then fallback to iso8601
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let server = try decoder.decode(ServerSettings.self, from: data)
            self.currentServer = server
            if server.isConnected {
                self.connectionStatus = .connected
                // Update NetworkService with saved URL
                NetworkService.shared.setBaseURL(server.serverURL)
            }
        } catch {
            // Try with iso8601 format as fallback
            decoder.dateDecodingStrategy = .iso8601
            if let server = try? decoder.decode(ServerSettings.self, from: data) {
                self.currentServer = server
                if server.isConnected {
                    self.connectionStatus = .connected
                    NetworkService.shared.setBaseURL(server.serverURL)
                }
            } else {
                // If both fail, clear the corrupted data
                print("Failed to decode saved server settings: \(error.localizedDescription)")
                UserDefaults.standard.removeObject(forKey: serverSettingsKey)
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
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .secondsSince1970
                if let encoded = try? encoder.encode(server) {
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

