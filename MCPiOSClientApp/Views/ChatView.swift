//
//  ChatView.swift
//  MCPiOSClient
//
//  Main chat interface optimized for iOS
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: AnthropicChatManager
    @State private var inputText = ""
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection status bar
                if !chatManager.isConnected {
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Not connected. Tap to configure.")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }
                }

                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(chatManager.messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }

                            if chatManager.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .id("loading")
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: chatManager.messages.count) { _ in
                        withAnimation {
                            if chatManager.isLoading {
                                proxy.scrollTo("loading", anchor: .bottom)
                            } else if let lastMessage = chatManager.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input area
                ChatInputView(
                    inputText: $inputText,
                    onSend: sendMessage,
                    isLoading: chatManager.isLoading
                )
            }
            .navigationTitle("MCP Chat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    chatManager.clearMessages()
                }) {
                    Image(systemName: "trash")
                }
                .disabled(chatManager.messages.isEmpty),
                trailing: Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            ServerConfigView()
                .environmentObject(chatManager)
        }
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = inputText
        inputText = ""

        Task {
            await chatManager.sendMessage(message)
        }
    }
}