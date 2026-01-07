//
//  IOSNotificationManager.swift
//  fileManager
//
//  Manager for iOS native notifications
//

import Foundation
import UserNotifications

class IOSNotificationManager {
    static let shared = IOSNotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    func showNotification(title: String, body: String, sound: UNNotificationSound = .default) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showDownloadProgressNotification(fileName: String, location: String, progress: Double) {
        let title = "Downloading..."
        let progressPercent = Int(progress * 100)
        let body = "\(fileName) from \(location)\n\(progressPercent)%"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil // No sound for progress updates
        
        let request = UNNotificationRequest(
            identifier: "download_\(fileName)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing download progress: \(error.localizedDescription)")
            }
        }
    }
    
    func showDownloadSuccessNotification(fileName: String, directory: String) {
        // Remove the progress notification first
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["download_\(fileName)"])
        
        let title = "Download Complete"
        let body = "\(fileName) from \(directory) downloaded successfully"
        showNotification(title: title, body: body)
    }
    
    func showDownloadErrorNotification(fileName: String, error: String) {
        // Remove the progress notification first
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["download_\(fileName)"])
        
        let title = "Download Failed"
        let body = "\(fileName): \(error)"
        showNotification(title: title, body: body)
    }
}

