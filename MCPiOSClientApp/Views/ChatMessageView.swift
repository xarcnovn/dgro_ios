//
//  ChatMessageView.swift
//  MCPiOSClient
//
//  iOS-optimized message display view
//

import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(avatarColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: avatarIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                // Role and timestamp
                HStack {
                    Text(roleTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(roleColor)

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Message content
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(messageBackground)
    }

    private var avatarColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return .purple
        case .tool:
            return .orange
        }
    }

    private var avatarIcon: String {
        switch message.role {
        case .user:
            return "person.fill"
        case .assistant:
            return "brain"
        case .tool:
            return "wrench.and.screwdriver.fill"
        }
    }

    private var roleTitle: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return "Claude"
        case .tool:
            return "Tool Result"
        }
    }

    private var roleColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return .purple
        case .tool:
            return .orange
        }
    }

    private var messageBackground: Color {
        switch message.role {
        case .user:
            return Color(.systemBackground)
        case .assistant:
            return Color(.secondarySystemBackground)
        case .tool:
            return Color(.tertiarySystemBackground)
        }
    }
}