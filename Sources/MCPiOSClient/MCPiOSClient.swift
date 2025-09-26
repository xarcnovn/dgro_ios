//
//  MCPiOSClient.swift
//  MCPiOSClient
//
//  Main library exports for the iOS MCP Client
//

import Foundation

// Re-export essential types and extensions
@_exported import MCPClient
@_exported import SwiftAnthropic

// Type aliases for convenience
public typealias AnthropicMessage = MessageParameter.Message
public typealias AnthropicTool = MessageParameter.Tool
public typealias AnthropicParameters = MessageParameter

// Package info
public struct MCPiOSClientInfo {
    public static let version = "1.0.0"
    public static let name = "MCPiOSClient"
}