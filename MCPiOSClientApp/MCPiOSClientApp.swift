//
//  MCPiOSClientApp.swift
//  MCPiOSClient
//
//  iOS MCP Client MVP - Anthropic Only
//

import SwiftUI
import SwiftAnthropic

@main
struct MCPiOSClientApp: App {
    @StateObject private var anthropicManager = AnthropicChatManager()

    var body: some Scene {
        WindowGroup {
            ChatView()
                .environmentObject(anthropicManager)
        }
    }
}