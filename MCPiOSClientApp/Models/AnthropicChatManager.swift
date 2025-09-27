//
//  AnthropicChatManager.swift
//  MCPiOSClient
//
//  Adapted for iOS with HTTPClientTransport
//

import Foundation
@preconcurrency import SwiftAnthropic
import MCPiOSClient
import MCP

@MainActor
final class AnthropicChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var serverURL: String = ""
    @Published var anthropicAPIKey: String = ""

    private var service: AnthropicService?
    private var mcpClient: Client?
    private var tools: [MessageParameter.Tool] = []

    func configure(apiKey: String) {
        anthropicAPIKey = apiKey
        service = AnthropicServiceFactory.service(apiKey: apiKey, betaHeaders: nil)
    }

    func connectToServer(url: String) async {
        serverURL = url
        connectionError = nil
        isConnected = false

        guard let endpoint = URL(string: url) else {
            connectionError = "Invalid URL"
            return
        }

        do {
            // Use HTTPClientTransport with streaming enabled
            let transport = HTTPClientTransport(
                endpoint: endpoint,
                streaming: true  // Enable Server-Sent Events for real-time updates
            )

            // Create client and connect
            let client = Client(name: "MCPiOSClient", version: "1.0.0")
            _ = try await client.connect(transport: transport)
            mcpClient = client

            // Discover available tools
            try await setupTools()
            isConnected = true

            messages.append(ChatMessage(
                role: .assistant,
                content: "Connected to MCP server at \(url). \(tools.count) tools available."
            ))
        } catch {
            connectionError = error.localizedDescription
            isConnected = false
        }
    }

    private func setupTools() async throws {
        guard let client = mcpClient else {
            tools = []
            return
        }
        tools = try await client.anthropicTools()
    }

    func sendMessage(_ prompt: String) async {
        guard service != nil else {
            messages.append(ChatMessage(
                role: .assistant,
                content: "Please configure your Anthropic API key first."
            ))
            return
        }

        isLoading = true

        // Add user message
        messages.append(ChatMessage(role: .user, content: prompt))

        // Build message history for context
        var messageHistory: [MessageParameter.Message] = messages.compactMap { message in
            switch message.role {
            case .user:
                return .init(role: .user, content: .text(message.content))
            case .assistant:
                return .init(role: .assistant, content: .text(message.content))
            case .tool:
                // Skip tool messages in history as they're handled differently in Anthropic
                return nil
            }
        }

        // Create message parameters
        let messageParameter = MessageParameter(
            model: .claude35Sonnet,
            messages: messageHistory,
            maxTokens: 4096,
            tools: tools.isEmpty ? nil : tools
        )

        do {
            guard let service = service else { return }
            let response = try await service.createMessage(messageParameter)

            // Check if the response uses a tool
            var hasToolUse = false
            var toolUse: MessageResponse.Content.ToolUse?

            for content in response.content {
                if case .toolUse(let tu) = content {
                    hasToolUse = true
                    toolUse = tu
                    break
                }
            }

            if hasToolUse, let toolUse = toolUse {
                // Handle tool use
                await handleToolUse(toolUse: toolUse, messageHistory: messageHistory)
            } else {
                // Regular text response
                let assistantMessage = response.content.compactMap { content -> String? in
                    switch content {
                    case .text(let textAndCitations):
                        return textAndCitations.0  // Get the text part of the tuple
                    default:
                        return nil
                    }
                }.joined(separator: "\n")

                messages.append(ChatMessage(role: .assistant, content: assistantMessage))
            }

        } catch {
            messages.append(ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)"))
        }

        isLoading = false
    }

    private func handleToolUse(toolUse: MessageResponse.Content.ToolUse, messageHistory: [MessageParameter.Message]) async {
        guard let mcpClient = mcpClient else {
            messages.append(ChatMessage(role: .assistant, content: "No MCP client available for tool execution"))
            return
        }

        messages.append(ChatMessage(role: .assistant, content: "Using tool: \(toolUse.name)"))

        do {
            let toolResult = try await mcpClient.anthropicCallTool(
                name: toolUse.name,
                arguments: toolUse.input
            )

            // Convert tool result to text
            let resultText = toolResult.compactMap { content -> String? in
                switch content {
                case .text(let text):
                    return text
                case .image(_):
                    return "Image: (base64 data)"
                default:
                    return nil
                }
            }.joined(separator: "\n")

            messages.append(ChatMessage(role: .tool, content: resultText))

            // Continue the conversation with the tool result
            await sendToolResultMessage(toolUse: toolUse, result: resultText, previousHistory: messageHistory)

        } catch {
            messages.append(ChatMessage(role: .assistant, content: "Tool execution failed: \(error.localizedDescription)"))
        }
    }

    private func sendToolResultMessage(toolUse: MessageResponse.Content.ToolUse, result: String, previousHistory: [MessageParameter.Message]) async {
        guard let service = service else { return }

        // Build message history including the tool use and result
        var messageHistory = previousHistory

        // Add the assistant's tool use
        messageHistory.append(.init(role: .assistant, content: .list([
            .toolUse(toolUse.id, toolUse.name, toolUse.input)
        ])))

        // Add the tool result
        messageHistory.append(.init(
            role: .user,
            content: .list([
                .toolResult(toolUse.id, result)
            ])
        ))

        // Continue the conversation
        let messageParameter = MessageParameter(
            model: .claude35Sonnet,
            messages: messageHistory,
            maxTokens: 4096,
            tools: tools.isEmpty ? nil : tools
        )

        do {
            let response = try await service.createMessage(messageParameter)

            let assistantMessage = response.content.compactMap { content -> String? in
                switch content {
                case .text(let textAndCitations):
                    return textAndCitations.0  // Get the text part of the tuple
                default:
                    return nil
                }
            }.joined(separator: "\n")

            messages.append(ChatMessage(role: .assistant, content: assistantMessage))

        } catch {
            messages.append(ChatMessage(role: .assistant, content: "Error continuing after tool use: \(error.localizedDescription)"))
        }
    }

    func clearMessages() {
        messages.removeAll()
    }
}