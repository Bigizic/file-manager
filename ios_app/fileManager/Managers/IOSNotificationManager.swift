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
    
    func showDownloadSuccessNotification(fileName: String, directory: String) {
        let title = "Download Complete"
        let body = "\(fileName) saved to \(directory) successfully"
        showNotification(title: title, body: body)
    }
}

