//
//  AppState.swift
//  fileManager
//
//  Global application state
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentPath: String = ""
    @Published var isConnected: Bool = false
    let notificationManager = NotificationManager()
    
    private init() {
        checkConnection()
    }
    
    func checkConnection() {
        Task {
            do {
                let service = NetworkService.shared
                let isConnected = try await service.checkConnection()
                await MainActor.run {
                    self.isConnected = isConnected
                }
            } catch {
                await MainActor.run {
                    self.isConnected = false
                    self.errorMessage = "Connection failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

