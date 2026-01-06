//
//  NotificationModel.swift
//  fileManager
//
//  Notification system for displaying messages to users
//

import SwiftUI

enum NotificationType {
    case error      // Center popup for errors
    case success    // Top banner for success/info
    case warning    // Center popup for warnings
}

struct NotificationItem: Identifiable {
    let id = UUID()
    let message: String
    let type: NotificationType
    let duration: TimeInterval
    
    init(message: String, type: NotificationType, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

class NotificationManager: ObservableObject {
    @Published var currentNotification: NotificationItem?
    @Published var showCenterPopup = false
    
    func show(_ notification: NotificationItem) {
        currentNotification = notification
        
        if notification.type == .error || notification.type == .warning {
            showCenterPopup = true
        }
        
        // Auto-dismiss after duration
        if notification.duration > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))
                await MainActor.run {
                    if notification.type == .error || notification.type == .warning {
                        self.showCenterPopup = false
                    } else {
                        self.currentNotification = nil
                    }
                }
            }
        }
    }
    
    func dismiss() {
        showCenterPopup = false
        currentNotification = nil
    }
}

struct NotificationView: ViewModifier {
    @ObservedObject var notificationManager: NotificationManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Top banner notification (success/info)
            if let notification = notificationManager.currentNotification,
               notification.type == .success {
                VStack {
                    TopBannerNotification(notification: notification)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .zIndex(1000)
            }
            
            // Center popup notification (errors/warnings)
            if notificationManager.showCenterPopup,
               let notification = notificationManager.currentNotification {
                CenterPopupNotification(notification: notification) {
                    notificationManager.dismiss()
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(1001)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notificationManager.currentNotification?.id)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notificationManager.showCenterPopup)
    }
}

struct TopBannerNotification: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
            
            Text(notification.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(UIColor.secondarySystemBackground)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct CenterPopupNotification: View {
    let notification: NotificationItem
    let onDismiss: () -> Void
    
    var iconName: String {
        switch notification.type {
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .error:
            return .red
        case .warning:
            return .orange
        case .success:
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            Text(notification.message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onDismiss) {
                Text("OK")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(iconColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(
            Color(UIColor.secondarySystemBackground)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func notificationOverlay(notificationManager: NotificationManager) -> some View {
        modifier(NotificationView(notificationManager: notificationManager))
    }
}

