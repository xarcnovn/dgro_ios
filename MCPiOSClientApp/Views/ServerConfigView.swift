//
//  ServerConfigView.swift
//  MCPiOSClient
//
//  Configuration view for MCP server and API settings
//

import SwiftUI

struct ServerConfigView: View {
    @EnvironmentObject var chatManager: AnthropicChatManager
    @Environment(\.dismiss) var dismiss

    @State private var serverURL = UserDefaults.standard.string(forKey: "mcp_server_url") ?? "http://localhost:3000"
    @State private var apiKey = ""
    @State private var isConnecting = false
    @State private var showAPIKeyAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("MCP Server") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Server URL", systemImage: "server.rack")
                            .font(.headline)
                        TextField("http://localhost:3000", text: $serverURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(.vertical, 4)

                    if let error = chatManager.connectionError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if chatManager.isConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected")
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                }

                Section("Anthropic API") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("API Key", systemImage: "key.fill")
                            .font(.headline)
                        SecureField("sk-ant-api...", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(.vertical, 4)

                    Button(action: {
                        showAPIKeyAlert = true
                    }) {
                        Label("How to get an API key?", systemImage: "questionmark.circle")
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: connect) {
                        if isConnecting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("Connecting...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Connect")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(serverURL.isEmpty || apiKey.isEmpty || isConnecting)
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Getting an API Key", isPresented: $showAPIKeyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Visit console.anthropic.com to create an account and generate an API key.")
        }
        .onAppear {
            // Load saved API key from Keychain if implemented
            // For MVP, just using in-memory storage
            apiKey = chatManager.anthropicAPIKey
        }
    }

    private func connect() {
        isConnecting = true

        // Save server URL
        UserDefaults.standard.set(serverURL, forKey: "mcp_server_url")

        // Configure API key
        chatManager.configure(apiKey: apiKey)

        // Connect to MCP server
        Task {
            await chatManager.connectToServer(url: serverURL)
            await MainActor.run {
                isConnecting = false
                if chatManager.isConnected {
                    dismiss()
                }
            }
        }
    }
}