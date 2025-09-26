//
//  ChatMessage.swift
//  MCPiOSClient
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()

    enum Role {
        case user
        case assistant
        case tool
    }
}