//
//  ServerConnectionView.swift
//  fileManager
//
//  Server connection dialog
//

import SwiftUI

struct ServerConnectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ServerConnectionViewModel()
    @State private var serverURL: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Connect to Server")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Enter server URL, IP address, or IP:port")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Server URL Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server Address")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("", text: $serverURL, prompt: Text("http://192.168.1.120:5000").foregroundColor(.secondary))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    Text("Examples: 192.168.1.120:5000, http://server.com, http://192.168.1.120")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Current Connection Status
                if let currentServer = viewModel.currentServer {
                    VStack(spacing: 12) {
                        Divider()
                            .background(Color(UIColor.separator))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Server")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(currentServer.serverURL)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                if let serverName = currentServer.serverName {
                                    Text(serverName)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if currentServer.isConnected {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Connected")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                        .cornerRadius(8)
                        
                        Button("Disconnect") {
                            viewModel.disconnect()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                
                // Error Message
                if let error = viewModel.connectionError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Connect Button
                Button(action: {
                    Task {
                        await viewModel.connectToServer(url: serverURL)
                        if viewModel.connectionStatus == .connected {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "link")
                        }
                        Text(viewModel.isConnecting ? "Connecting..." : "Connect")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isConnecting || serverURL.isEmpty)
                .opacity((viewModel.isConnecting || serverURL.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                if let currentServer = viewModel.currentServer {
                    serverURL = currentServer.serverURL
                }
            }
        }
    }
}

#Preview {
    ServerConnectionView()
}
