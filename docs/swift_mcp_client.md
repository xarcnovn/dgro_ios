# MCPSwiftWrapper Repository Clone

## Repository Structure

```
MCPSwiftWrapper/
├── .gitignore
├── LICENSE
├── Package.resolved
├── Package.swift
├── README.md
├── Sources/
│   └── MCPSwiftWrapper/
│       ├── MCPSwiftWrapper.swift
│       └── MCP/
│           ├── MCPTool+AnthropicTool.swift
│           └── MCPTool+OpenAITool.swift
├── Tests/
│   └── MCPSwiftWrapperTests/
│       └── MCPSwiftWrapperTests.swift
└── Example/
    └── MCPClientChat/
        ├── MCPClientChat.xcodeproj/
        │   └── project.pbxproj
        └── MCPClientChat/
            ├── ContentView.swift
            ├── MCPClientChatApp.swift
            ├── MCPClientChat.entitlements
            ├── Assets.xcassets/
            │   └── Contents.json
            ├── Preview Content/
            ├── Chat/
            │   ├── Models/
            │   │   ├── AnthropicNonStreamManager.swift
            │   │   ├── ChatManager.swift
            │   │   ├── ChatMessage.swift
            │   │   └── OpenAIChatNonStreamManager.swift
            │   └── UI/
            │       ├── ChatInputView.swift
            │       ├── ChatMessageView.swift
            │       └── ChatView.swift
            └── MCP/
                └── Clients/
                    ├── ClaudeCodeMCPClient.swift
                    └── GithubMCPClient.swift
```

## File Contents

### .gitignore
```
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/configuration/registries.json
.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
.netrc
```

### LICENSE
```
MIT License

Copyright (c) 2025 James Rochabrun

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Package.resolved
```json
{
  "originHash" : "c48af21a5bb32ded9dd4e7d91a4b7f0c1b0e59d5dc6bb0816b6797b9e18f9faa",
  "pins" : [
    {
      "identity" : "jsonrpc",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/randomeizer/JSONRPC",
      "state" : {
        "revision" : "65b9d63a3bd4aba8e8b2e44d98e1a27e10fafb26",
        "version" : "0.9.1"
      }
    },
    {
      "identity" : "mcp-swift-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/modelcontextprotocol/mcp-swift-sdk",
      "state" : {
        "revision" : "a7d86a5cb58e12e6b4509a3b5dcdc0e1abfeb87f",
        "version" : "0.2.3"
      }
    },
    {
      "identity" : "swift-json-schema",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/ajevans99/swift-json-schema",
      "state" : {
        "revision" : "c32a7ae4d9e6b7b651a7cc27f8e4bf55b83d7c3c",
        "version" : "0.3.2"
      }
    },
    {
      "identity" : "swift-syntax",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/swiftlang/swift-syntax",
      "state" : {
        "revision" : "515f79b522918f83483068d99c68daeb5116342d",
        "version" : "600.0.1"
      }
    },
    {
      "identity" : "swiftanthropic",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/jamesrochabrun/SwiftAnthropic",
      "state" : {
        "revision" : "18ad79d7b0a15b9e0c81fde7ad8d0c6adecc3830",
        "version" : "2.1.3"
      }
    },
    {
      "identity" : "swiftopenai",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/jamesrochabrun/SwiftOpenAI",
      "state" : {
        "revision" : "9b4b7abeb7bdcb2b60a7d1b28fbbeda8ddf0644e",
        "version" : "4.0.3"
      }
    }
  ],
  "version" : 3
}
```

### Package.swift
```swift
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MCPSwiftWrapper",
    platforms: [
      .macOS(.v14),
    ],
    products: [
        .library(
            name: "MCPSwiftWrapper",
            targets: ["MCPSwiftWrapper"]),
    ],
    dependencies: [
      .package(url: "https://github.com/gsabran/mcp-swift-sdk", from: "0.2.2"),
      .package(url: "https://github.com/jamesrochabrun/SwiftOpenAI", from: "4.0.3"),
      .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", from: "2.1.2"),
    ],
    targets: [
        .target(
            name: "MCPSwiftWrapper",
            dependencies: [
               .product(name: "SwiftOpenAI", package: "SwiftOpenAI"),
               .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
              .product(name: "MCPClient", package: "mcp-swift-sdk"),
            ]),
        .testTarget(
            name: "MCPSwiftWrapperTests",
            dependencies: ["MCPSwiftWrapper"]
        ),
    ]
)
```

### README.md
```markdown
# MCPSwiftWrapper

MCPSwiftWrapper is a light wrapper around [mcp-swift-sdk](https://github.com/modelcontextprotocol/mcp-swift-sdk) for easy usage of MCP clients in Swift.

The wrapper integrates with [SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI) and [SwiftAnthropic](https://github.com/jamesrochabrun/SwiftAnthropic) libraries to enable seamless tool usage, MCP allows the AI models to "discover available tools" and "call these tools with parameters".

## Requirements

- macOS 14.0+
- Swift 6.0+
- Xcode 16.0+
- npm, npx installed.

## Important

When building a client macOS app, you need to disable the app sandbox since the app needs to run processes for each MCP server.

## Installation

Add MCPSwiftWrapper to your project via Swift Package Manager or Xcode directly, through File > Add Package Dependencies.

## Usage

### Creating an MCP Client

```swift
let githubClient = try await MCPClient(
    info: .init(name: "GithubMCPClient", version: "1.0.0"),
    transport: .stdioProcess(
        "npx",
        args: ["-y", "@modelcontextprotocol/server-github"],
        verbose: true),
    capabilities: .init())
```

This creates a GitHub MCP client that initializes with MCPClient using transport .stdioProcess to run the [@modelcontextprotocol/server-github](https://github.com/modelcontextprotocol/servers/tree/main/src/github) npm package.

### Usage with OpenAI

```swift
import SwiftOpenAI
import MCPSwiftWrapper

// Initialize the client
let service = OpenAIServiceFactory.service(apiKey: "<API_KEY>")
let chatManager = OpenAIChatNonStreamManager(service: service)

// Get tools from MCP Client
let tools = try await client.openAITools()

// Request OpenAI with tools
let parameters = ChatCompletionParameters(
    messages: [.init(role: .user, content: .text("Search for Swift repositories"))],
    model: .gpt4o,
    tools: tools
)

let response = try await service.startChat(parameters: parameters)

// Handle tool calls
if let toolCalls = response.choices.first?.message.toolCalls {
    for toolCall in toolCalls {
        let result = try await client.openAICallTool(toolCall: toolCall)
        // Handle result...
    }
}
```

### Usage with Anthropic

```swift
import SwiftAnthropic
import MCPSwiftWrapper

// Initialize the client
let service = AnthropicServiceFactory.service(apiKey: "<API_KEY>")

// Get tools from MCP Client
let tools = try await client.anthropicTools()

// Request Anthropic with tools
let messageParameter = MessageParameter(
    model: .claude35Sonnet,
    maxTokens: 1000,
    messages: [.init(role: .user, content: [.text("Search for Swift repositories")])],
    tools: tools
)

let response = try await service.createMessage(messageParameter)

// Handle tool use
if let toolUse = response.content.first?.asToolUse {
    let result = try await client.anthropicCallTool(
        name: toolUse.name,
        arguments: toolUse.input
    )
    // Handle result...
}
```

## Example

A complete implementation can be found in the MCPSwiftWrapper package under [Example/MCPClientChat](https://github.com/jamesrochabrun/MCPSwiftWrapper/tree/main/Example/MCPClientChat).

## Related

- [SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI)
- [SwiftAnthropic](https://github.com/jamesrochabrun/SwiftAnthropic)
- [mcp-swift-sdk](https://github.com/modelcontextprotocol/mcp-swift-sdk)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [MCP Servers](https://github.com/modelcontextprotocol/servers)

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for details.
```

### Sources/MCPSwiftWrapper/MCPSwiftWrapper.swift
```swift
// The Swift Programming Language
// https://docs.swift.org/swift-book
@_exported import SwiftAnthropic
@_exported import SwiftOpenAI
@_exported import MCPClient

public typealias AnthropicMessage = SwiftAnthropic.MessageParameter.Message
public typealias AnthropicTool = SwiftAnthropic.MessageParameter.Tool
public typealias AnthropicParameters = SwiftAnthropic.MessageParameter

public typealias OpenAITool = SwiftOpenAI.ChatCompletionParameters.Tool
public typealias OpenAIToolCall = SwiftOpenAI.ToolCall
public typealias OpenAIMessage = SwiftOpenAI.ChatCompletionParameters.Message
public typealias OpenAIParameters = SwiftOpenAI.ChatCompletionParameters
```

### Sources/MCPSwiftWrapper/MCP/MCPTool+AnthropicTool.swift
```swift
//
//  MCPTool+AnthropicTool.swift
//  MCPSwiftWrapper
//
//  Created by James Rochabrun on 3/3/25.
//

import Foundation
import MCPClient
@_exported import SwiftAnthropic

// MARK: - Anthropic conversions

extension MCPClient {

  /// Returns an array of Anthropic tools by converting MCP tools.
  public func anthropicTools() async throws -> [AnthropicTool] {
    let tools = try await self.listTools()
    return tools.compactMap { $0.anthropicTool() }
  }

  /// Calls an MCP tool with the given name and arguments and returns the result.
  /// - Parameters:
  ///   - name: The name of the tool to call
  ///   - arguments: The arguments to pass to the tool as an Encodable object
  /// - Returns: The result of the tool call as an AnthropicMessage.Content
  /// - Throws: If the tool call fails or returns an error
  public func anthropicCallTool<T: Encodable>(name: String, arguments: T) async throws -> AnthropicMessage.Content {
    let result = try await self.callTool(name: name, arguments: arguments)

    // Check if result has isError flag
    if let isError = result.isError, isError {
      throw MCPToolError.callFailed(result.content ?? [])
    }

    // Convert MCPToolCallResult.Content to AnthropicMessage.Content
    return result.content?.compactMap { content in
      switch content {
      case .text(let textContent):
        return .text(textContent.text)
      case .image(let imageContent):
        // Extract base64 from data URL if present
        if let dataURL = imageContent.data,
           dataURL.hasPrefix("data:"),
           let base64Start = dataURL.range(of: ";base64,") {
          let base64Data = String(dataURL[base64Start.upperBound...])
          let mimeType = String(dataURL[dataURL.index(after: dataURL.startIndex)..<base64Start.lowerBound])
            .replacingOccurrences(of: "data:", with: "")

          return .image(.init(
            type: .base64,
            mediaType: mimeType,
            data: base64Data,
            detail: nil
          ))
        }
        return nil
      case .resource(let resourceContent):
        // Convert resource to text representation
        if let text = resourceContent.resource?.text {
          return .text(text)
        } else if let blob = resourceContent.resource?.blob {
          return .text("Resource blob: \(blob)")
        }
        return nil
      }
    } ?? []
  }
}

extension Tool {
  /// Converts an MCP Tool to an Anthropic Tool format
  func anthropicTool() -> AnthropicTool? {

    let inputSchema = self.inputSchema

    // Parse the JSON schema
    guard let schemaData = try? JSONSerialization.data(withJSONObject: inputSchema),
          let schema = try? JSONDecoder().decode(JSONSchema.self, from: schemaData) else {
      return nil
    }

    // Convert to Anthropic's input schema format
    let anthropicInputSchema = schema.toAnthropicInputSchema()

    return AnthropicTool(
      name: self.name,
      description: self.description ?? "",
      inputSchema: anthropicInputSchema,
      cacheControl: nil
    )
  }
}

// MARK: - JSON Schema Types

struct JSONSchema: Codable {
  let type: String?
  let properties: [String: JSONSchemaProperty]?
  let required: [String]?
  let description: String?
  let additionalProperties: Bool?

  func toAnthropicInputSchema() -> AnthropicTool.InputSchema {
    var schemaDict: [String: Any] = ["type": "object"]

    if let properties = properties {
      var propsDict: [String: Any] = [:]
      for (key, prop) in properties {
        propsDict[key] = prop.toDictionary()
      }
      schemaDict["properties"] = propsDict
    }

    if let required = required {
      schemaDict["required"] = required
    }

    if let additionalProperties = additionalProperties {
      schemaDict["additionalProperties"] = additionalProperties
    }

    return .init(schemaDict)
  }
}

struct JSONSchemaProperty: Codable {
  let type: JSONSchemaType?
  let description: String?
  let items: JSONSchemaItems?
  let properties: [String: JSONSchemaProperty]?
  let required: [String]?
  let `enum`: [String]?
  let format: String?
  let pattern: String?
  let minimum: Double?
  let maximum: Double?
  let minLength: Int?
  let maxLength: Int?
  let `default`: AnyCodable?
  let oneOf: [JSONSchemaProperty]?
  let anyOf: [JSONSchemaProperty]?

  func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [:]

    if let type = type {
      dict["type"] = type.rawValue
    }

    if let description = description {
      dict["description"] = description
    }

    if let items = items {
      dict["items"] = items.toDictionary()
    }

    if let properties = properties {
      var propsDict: [String: Any] = [:]
      for (key, prop) in properties {
        propsDict[key] = prop.toDictionary()
      }
      dict["properties"] = propsDict
    }

    if let required = required {
      dict["required"] = required
    }

    if let enumValues = self.enum {
      dict["enum"] = enumValues
    }

    if let format = format {
      dict["format"] = format
    }

    if let pattern = pattern {
      dict["pattern"] = pattern
    }

    if let minimum = minimum {
      dict["minimum"] = minimum
    }

    if let maximum = maximum {
      dict["maximum"] = maximum
    }

    if let minLength = minLength {
      dict["minLength"] = minLength
    }

    if let maxLength = maxLength {
      dict["maxLength"] = maxLength
    }

    if let defaultValue = self.default {
      dict["default"] = defaultValue.value
    }

    if let oneOf = oneOf {
      dict["oneOf"] = oneOf.map { $0.toDictionary() }
    }

    if let anyOf = anyOf {
      dict["anyOf"] = anyOf.map { $0.toDictionary() }
    }

    return dict
  }
}

struct JSONSchemaItems: Codable {
  let type: JSONSchemaType?
  let description: String?
  let properties: [String: JSONSchemaProperty]?
  let required: [String]?
  let `enum`: [String]?

  func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [:]

    if let type = type {
      dict["type"] = type.rawValue
    }

    if let description = description {
      dict["description"] = description
    }

    if let properties = properties {
      var propsDict: [String: Any] = [:]
      for (key, prop) in properties {
        propsDict[key] = prop.toDictionary()
      }
      dict["properties"] = propsDict
    }

    if let required = required {
      dict["required"] = required
    }

    if let enumValues = self.enum {
      dict["enum"] = enumValues
    }

    return dict
  }
}

enum JSONSchemaType: String, Codable {
  case string
  case number
  case integer
  case boolean
  case array
  case object
  case null
}

// Helper type for handling any codable value
struct AnyCodable: Codable {
  let value: Any

  init(_ value: Any) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let intValue = try? container.decode(Int.self) {
      value = intValue
    } else if let doubleValue = try? container.decode(Double.self) {
      value = doubleValue
    } else if let boolValue = try? container.decode(Bool.self) {
      value = boolValue
    } else if let stringValue = try? container.decode(String.self) {
      value = stringValue
    } else if let arrayValue = try? container.decode([AnyCodable].self) {
      value = arrayValue.map { $0.value }
    } else if let dictValue = try? container.decode([String: AnyCodable].self) {
      value = dictValue.mapValues { $0.value }
    } else {
      value = NSNull()
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let intValue as Int:
      try container.encode(intValue)
    case let doubleValue as Double:
      try container.encode(doubleValue)
    case let boolValue as Bool:
      try container.encode(boolValue)
    case let stringValue as String:
      try container.encode(stringValue)
    default:
      try container.encodeNil()
    }
  }
}

// MARK: - Errors

enum MCPToolError: LocalizedError {
  case callFailed([MCPToolCallResult.Content])

  var errorDescription: String? {
    switch self {
    case .callFailed(let content):
      let errorTexts = content.compactMap { c -> String? in
        if case .text(let textContent) = c {
          return textContent.text
        }
        return nil
      }
      return "Tool call failed: \(errorTexts.joined(separator: ", "))"
    }
  }
}
```

### Sources/MCPSwiftWrapper/MCP/MCPTool+OpenAITool.swift
```swift
//
//  MCPTool+OpenAITool.swift
//  MCPSwiftWrapper
//
//  Created by James Rochabrun on 3/3/25.
//

import Foundation
import MCPClient
@_exported import SwiftOpenAI

// MARK: - OpenAI conversions

extension MCPClient {

  /// Returns an array of OpenAI tools by converting MCP tools.
  public func openAITools() async throws -> [OpenAITool] {
    let tools = try await self.listTools()
    return tools.compactMap { $0.openAITool() }
  }

  /// Calls an MCP tool using OpenAI's tool call format and returns the result.
  /// - Parameter toolCall: The OpenAI tool call containing the function name and arguments
  /// - Returns: The result of the tool call as an OpenAIMessage
  /// - Throws: If the tool call fails or returns an error
  public func openAICallTool(toolCall: OpenAIToolCall) async throws -> OpenAIMessage {
    // Parse the arguments string into a dictionary
    let arguments: [String: Any]
    if let data = toolCall.function.arguments.data(using: .utf8),
       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      arguments = parsed
    } else {
      arguments = [:]
    }

    // Call the tool with parsed arguments
    let result = try await self.callTool(
      name: toolCall.function.name,
      arguments: arguments
    )

    // Check if result has isError flag
    if let isError = result.isError, isError {
      let errorContent = result.content?.compactMap { content -> String? in
        if case .text(let textContent) = content {
          return textContent.text
        }
        return nil
      }.joined(separator: ", ") ?? "Unknown error"

      throw MCPToolError.callFailed(result.content ?? [])
    }

    // Convert result to OpenAI message format
    let toolContent = result.content?.compactMap { content -> String? in
      switch content {
      case .text(let textContent):
        return textContent.text
      case .image(let imageContent):
        // For images, we can return a description or the data URL
        return imageContent.data ?? "Image content"
      case .resource(let resourceContent):
        // Convert resource to text representation
        if let text = resourceContent.resource?.text {
          return text
        } else if let blob = resourceContent.resource?.blob {
          return "Resource blob: \(blob)"
        }
        return nil
      }
    }.joined(separator: "\n") ?? ""

    return OpenAIMessage(
      role: .tool,
      content: .text(toolContent),
      name: nil,
      toolCallID: toolCall.id,
      refusal: nil
    )
  }
}

extension Tool {
  /// Converts an MCP Tool to an OpenAI Tool format
  func openAITool() -> OpenAITool? {
    let inputSchema = self.inputSchema

    // Parse the JSON schema
    guard let schemaData = try? JSONSerialization.data(withJSONObject: inputSchema),
          let schema = try? JSONDecoder().decode(OpenAIJSONSchema.self, from: schemaData) else {
      return nil
    }

    // Convert to OpenAI's function parameters format
    let parameters = schema.toOpenAIParameters()

    return OpenAITool(
      type: .function,
      function: .init(
        name: self.name,
        description: self.description,
        parameters: parameters,
        strict: nil
      )
    )
  }
}

// MARK: - OpenAI JSON Schema Types

struct OpenAIJSONSchema: Codable {
  let type: String?
  let properties: [String: OpenAIJSONSchemaProperty]?
  let required: [String]?
  let description: String?
  let additionalProperties: Bool?

  func toOpenAIParameters() -> JSONSchema {
    var schemaDict: [String: Any] = ["type": "object"]

    if let properties = properties {
      var propsDict: [String: Any] = [:]
      for (key, prop) in properties {
        propsDict[key] = prop.toDictionary()
      }
      schemaDict["properties"] = propsDict
    }

    if let required = required {
      schemaDict["required"] = required
    }

    if let additionalProperties = additionalProperties {
      schemaDict["additionalProperties"] = additionalProperties
    }

    return .init(schemaDict)
  }
}

struct OpenAIJSONSchemaProperty: Codable {
  let type: OpenAIJSONSchemaType?
  let description: String?
  let items: OpenAIJSONSchemaItems?
  let properties: [String: OpenAIJSONSchemaProperty]?
  let required: [String]?
  let `enum`: [String]?
  let format: String?
  let pattern: String?
  let minimum: Double?
  let maximum: Double?
  let minLength: Int?
  let maxLength: Int?
  let `default`: OpenAIAnyCodable?
  let oneOf: [OpenAIJSONSchemaProperty]?
  let anyOf: [OpenAIJSONSchemaProperty]?

  func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [:]

    if let type = type {
      dict["type"] = type.rawValue
    }

    if let description = description {
      dict["description"] = description
    }

    if let items = items {
      dict["items"] = items.toDictionary()
    }

    if let properties = properties {
      var propsDict: [String: Any] = [:]
      for (key, prop) in properties {
        propsDict[key] = prop.toDictionary()
      }
      dict["properties"] = propsDict
    }

    if let required = required {
      dict["required"] = required
    }

    if let enumValues = self.enum {
      dict["enum"] = enumValues
    }

    if let format = format {
      dict["format"] = format
    }

    if let pattern = pattern {
      dict["pattern"] = pattern
    }

    if let minimum = minimum {
      dict["minimum"] = minimum
    }

    if let maximum = maximum {
      dict["maximum"] = maximum
    }

    if let minLength = minLength {
      dict["minLength"] = minLength
    }

    if let maxLength = maxLength {
      dict["maxLength"] = maxLength
    }

    if let defaultValue = self.default {
      dict["default"] = defaultValue.value
    }

    if let oneOf = oneOf {
      dict["oneOf"] = oneOf.map { $0.toDictionary() }
    }

    if let anyOf = anyOf {
      dict["anyOf"] = anyOf.map { $0.toDictionary() }
    }

    return dict
  }
}

struct OpenAIJSONSchemaItems: Codable {
  let type: OpenAIJSONSchemaType?
  let description: String?
  let properties: [String: OpenAIJSONSchemaProperty]?
  let required: [String]?
  let `enum`: [String]?

  func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [:]

    if let type = type {
      dict["type"] = type.rawValue
    }

    if let description = description {
      dict["description"] = description
    }

    if let properties = properties {
      var propsDict: [String: Any] = [:]
      for (key, prop) in properties {
        propsDict[key] = prop.toDictionary()
      }
      dict["properties"] = propsDict
    }

    if let required = required {
      dict["required"] = required
    }

    if let enumValues = self.enum {
      dict["enum"] = enumValues
    }

    return dict
  }
}

enum OpenAIJSONSchemaType: String, Codable {
  case string
  case number
  case integer
  case boolean
  case array
  case object
  case null
}

// Helper type for handling any codable value
struct OpenAIAnyCodable: Codable {
  let value: Any

  init(_ value: Any) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let intValue = try? container.decode(Int.self) {
      value = intValue
    } else if let doubleValue = try? container.decode(Double.self) {
      value = doubleValue
    } else if let boolValue = try? container.decode(Bool.self) {
      value = boolValue
    } else if let stringValue = try? container.decode(String.self) {
      value = stringValue
    } else if let arrayValue = try? container.decode([OpenAIAnyCodable].self) {
      value = arrayValue.map { $0.value }
    } else if let dictValue = try? container.decode([String: OpenAIAnyCodable].self) {
      value = dictValue.mapValues { $0.value }
    } else {
      value = NSNull()
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let intValue as Int:
      try container.encode(intValue)
    case let doubleValue as Double:
      try container.encode(doubleValue)
    case let boolValue as Bool:
      try container.encode(boolValue)
    case let stringValue as String:
      try container.encode(stringValue)
    default:
      try container.encodeNil()
    }
  }
}
```

### Tests/MCPSwiftWrapperTests/MCPSwiftWrapperTests.swift
```swift
import Testing
@testable import MCPSwiftWrapper

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}
```

### Example/MCPClientChat/MCPClientChat/ContentView.swift
```swift
//
//  ContentView.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import MCPClient
import SwiftAnthropic
import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
```

### Example/MCPClientChat/MCPClientChat/MCPClientChatApp.swift
```swift
//
//  MCPClientChatApp.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import MCPSwiftWrapper
import SwiftUI
import SwiftAnthropic
import SwiftOpenAI

@main
struct MCPClientChatApp: App {

  @StateObject private var anthropicNonStreamManager = AnthropicNonStreamManager(
    service: AnthropicServiceFactory.service(apiKey: "YOUR_API_KEY"))

  @StateObject private var openAINonStreamManager = OpenAIChatNonStreamManager(
    service: OpenAIServiceFactory.service(apiKey: "YOUR_API_KEY"))

  var body: some Scene {
    WindowGroup {
      ChatView()
        .environmentObject(anthropicNonStreamManager)
        .environmentObject(openAINonStreamManager)
    }
  }
}
```

### Example/MCPClientChat/MCPClientChat/MCPClientChat.entitlements
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
```

### Example/MCPClientChat/MCPClientChat/Assets.xcassets/Contents.json
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### Example/MCPClientChat/MCPClientChat/Chat/Models/AnthropicNonStreamManager.swift
```swift
//
//  AnthropicNonStreamManager.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import Foundation
import SwiftAnthropic
import MCPClient
import MCPSwiftWrapper

@MainActor
final class AnthropicNonStreamManager: ChatManager {

  private let service: AnthropicService
  private var client: MCPClient?
  private var tools: [AnthropicTool] = []

  init(service: AnthropicService) {
    self.service = service
  }

  override func setClient(_ client: MCPClient) {
    self.client = client
  }

  override func setupTools() async throws {
    guard let client = client else {
      tools = []
      return
    }
    tools = try await client.anthropicTools()
  }

  override func sendMessage(_ prompt: String) async {
    isLoading = true

    // Build message history for context
    var messageHistory: [AnthropicMessage] = messages.compactMap { message in
      switch message.role {
      case .user:
        return .init(role: .user, content: [.text(message.content)])
      case .assistant:
        return .init(role: .assistant, content: [.text(message.content)])
      case .tool:
        // Skip tool messages in history as they're handled differently in Anthropic
        return nil
      }
    }

    // Add the new user message
    messageHistory.append(.init(role: .user, content: [.text(prompt)]))

    // Create message parameters
    let messageParameter = MessageParameter(
      model: .claude35Sonnet,
      messages: messageHistory,
      maxTokens: 4096,
      tools: tools.isEmpty ? nil : tools
    )

    do {
      let response = try await service.createMessage(messageParameter)

      // Check if the response uses a tool
      if let toolUse = response.content.first(where: { content in
        if case .toolUse = content {
          return true
        }
        return false
      })?.asToolUse {
        // Handle tool use
        guard let client = client else {
          appendMessage(ChatMessage(role: .assistant, content: "No MCP client available for tool execution"))
          isLoading = false
          return
        }

        appendMessage(ChatMessage(role: .assistant, content: "Using tool: \(toolUse.name)"))

        do {
          let toolResult = try await client.anthropicCallTool(
            name: toolUse.name,
            arguments: toolUse.input
          )

          // Convert tool result to text
          let resultText = toolResult.compactMap { content -> String? in
            switch content {
            case .text(let text):
              return text
            case .image(let image):
              return "Image: \(image.source)"
            default:
              return nil
            }
          }.joined(separator: "\n")

          appendMessage(ChatMessage(role: .tool, content: resultText))

          // Continue the conversation with the tool result
          await sendToolResultMessage(toolUse: toolUse, result: resultText)

        } catch {
          appendMessage(ChatMessage(role: .assistant, content: "Tool execution failed: \(error.localizedDescription)"))
        }
      } else {
        // Regular text response
        let assistantMessage = response.content.compactMap { content -> String? in
          switch content {
          case .text(let text):
            return text
          default:
            return nil
          }
        }.joined(separator: "\n")

        appendMessage(ChatMessage(role: .assistant, content: assistantMessage))
      }

    } catch {
      appendMessage(ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)"))
    }

    isLoading = false
  }

  private func sendToolResultMessage(toolUse: MessageParameter.Message.Content.ToolUse, result: String) async {
    // Build message history including the tool use and result
    var messageHistory: [AnthropicMessage] = messages.compactMap { message in
      switch message.role {
      case .user:
        return .init(role: .user, content: [.text(message.content)])
      case .assistant:
        // Skip the "Using tool" message we added for UI
        if !message.content.starts(with: "Using tool:") {
          return .init(role: .assistant, content: [.text(message.content)])
        }
        return nil
      case .tool:
        // Skip tool results from history as we'll add them properly
        return nil
      }
    }

    // Add the assistant's tool use
    messageHistory.append(.init(role: .assistant, content: [.toolUse(toolUse)]))

    // Add the tool result
    messageHistory.append(.init(
      role: .user,
      content: [.toolResult(.init(toolUseID: toolUse.id, content: result))]
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
        case .text(let text):
          return text
        default:
          return nil
        }
      }.joined(separator: "\n")

      appendMessage(ChatMessage(role: .assistant, content: assistantMessage))

    } catch {
      appendMessage(ChatMessage(role: .assistant, content: "Error continuing after tool use: \(error.localizedDescription)"))
    }
  }
}
```

### Example/MCPClientChat/MCPClientChat/Chat/Models/ChatManager.swift
```swift
//
//  ChatManager.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import Foundation
import MCPClient

@MainActor
class ChatManager: ObservableObject {
  @Published var messages: [ChatMessage] = []
  @Published var isLoading = false

  func setClient(_ client: MCPClient) {
    // Override in subclass
  }

  func setupTools() async throws {
    // Override in subclass
  }

  func sendMessage(_ prompt: String) async {
    // Override in subclass
  }

  func appendMessage(_ message: ChatMessage) {
    messages.append(message)
  }

  func clearMessages() {
    messages.removeAll()
  }
}
```

### Example/MCPClientChat/MCPClientChat/Chat/Models/ChatMessage.swift
```swift
//
//  ChatMessage.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
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
```

### Example/MCPClientChat/MCPClientChat/Chat/Models/OpenAIChatNonStreamManager.swift
```swift
//
//  OpenAIChatNonStreamManager.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import Foundation
import SwiftOpenAI
import MCPClient
import MCPSwiftWrapper

@MainActor
final class OpenAIChatNonStreamManager: ChatManager {

  private let service: OpenAIService
  private var client: MCPClient?
  private var tools: [OpenAITool] = []

  init(service: OpenAIService) {
    self.service = service
  }

  override func setClient(_ client: MCPClient) {
    self.client = client
  }

  override func setupTools() async throws {
    guard let client = client else {
      tools = []
      return
    }
    tools = try await client.openAITools()
  }

  override func sendMessage(_ prompt: String) async {
    isLoading = true

    // Build message history for context
    var messageHistory: [OpenAIMessage] = messages.compactMap { message in
      switch message.role {
      case .user:
        return .init(role: .user, content: .text(message.content))
      case .assistant:
        return .init(role: .assistant, content: .text(message.content))
      case .tool:
        // OpenAI expects tool messages with specific format
        return .init(role: .tool, content: .text(message.content))
      }
    }

    // Add the new user message
    messageHistory.append(.init(role: .user, content: .text(prompt)))

    // Create chat parameters
    let parameters = ChatCompletionParameters(
      messages: messageHistory,
      model: .gpt4o,
      tools: tools.isEmpty ? nil : tools
    )

    do {
      let response = try await service.startChat(parameters: parameters)

      guard let choice = response.choices.first else {
        appendMessage(ChatMessage(role: .assistant, content: "No response received"))
        isLoading = false
        return
      }

      // Check if the response includes tool calls
      if let toolCalls = choice.message.toolCalls, !toolCalls.isEmpty {

        guard let client = client else {
          appendMessage(ChatMessage(role: .assistant, content: "No MCP client available for tool execution"))
          isLoading = false
          return
        }

        for toolCall in toolCalls {
          appendMessage(ChatMessage(role: .assistant, content: "Using tool: \(toolCall.function.name)"))

          do {
            let toolMessage = try await client.openAICallTool(toolCall: toolCall)

            // Extract the content from the tool message
            if case .text(let resultText) = toolMessage.content {
              appendMessage(ChatMessage(role: .tool, content: resultText))
            }

            // Continue the conversation with the tool result
            await sendToolResultMessage(toolCall: toolCall, toolMessage: toolMessage)

          } catch {
            appendMessage(ChatMessage(role: .assistant, content: "Tool execution failed: \(error.localizedDescription)"))
          }
        }
      } else {
        // Regular text response
        if case .text(let content) = choice.message.content {
          appendMessage(ChatMessage(role: .assistant, content: content))
        }
      }

    } catch {
      appendMessage(ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)"))
    }

    isLoading = false
  }

  private func sendToolResultMessage(toolCall: OpenAIToolCall, toolMessage: OpenAIMessage) async {
    // Build message history including the tool call and result
    var messageHistory: [OpenAIMessage] = messages.compactMap { message in
      switch message.role {
      case .user:
        return .init(role: .user, content: .text(message.content))
      case .assistant:
        // Skip the "Using tool" message we added for UI
        if !message.content.starts(with: "Using tool:") {
          return .init(role: .assistant, content: .text(message.content))
        }
        return nil
      case .tool:
        return nil // We'll add the proper tool message
      }
    }

    // Add the assistant's tool call message
    messageHistory.append(.init(
      role: .assistant,
      content: nil,
      toolCalls: [toolCall]
    ))

    // Add the tool result message
    messageHistory.append(toolMessage)

    // Continue the conversation
    let parameters = ChatCompletionParameters(
      messages: messageHistory,
      model: .gpt4o,
      tools: tools.isEmpty ? nil : tools
    )

    do {
      let response = try await service.startChat(parameters: parameters)

      if let choice = response.choices.first,
         case .text(let content) = choice.message.content {
        appendMessage(ChatMessage(role: .assistant, content: content))
      }

    } catch {
      appendMessage(ChatMessage(role: .assistant, content: "Error continuing after tool use: \(error.localizedDescription)"))
    }
  }
}
```

### Example/MCPClientChat/MCPClientChat/Chat/UI/ChatInputView.swift
```swift
//
//  ChatInputView.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import SwiftUI

struct ChatInputView: View {
  @Binding var inputText: String
  let onSend: () -> Void
  let isLoading: Bool

  var body: some View {
    HStack(spacing: 12) {
      TextField("Type a message...", text: $inputText, axis: .vertical)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .onSubmit {
          if !inputText.isEmpty && !isLoading {
            onSend()
          }
        }

      Button(action: onSend) {
        Image(systemName: "paperplane.fill")
          .font(.system(size: 16))
      }
      .disabled(inputText.isEmpty || isLoading)
      .buttonStyle(PlainButtonStyle())
    }
    .padding()
    .background(Color(.windowBackgroundColor))
  }
}
```

### Example/MCPClientChat/MCPClientChat/Chat/UI/ChatMessageView.swift
```swift
//
//  ChatMessageView.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import SwiftUI

struct ChatMessageView: View {
  let message: ChatMessage

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // Avatar
      Circle()
        .fill(avatarColor)
        .frame(width: 32, height: 32)
        .overlay(
          Text(avatarInitial)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
        )

      VStack(alignment: .leading, spacing: 4) {
        // Role and timestamp
        HStack {
          Text(roleTitle)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)

          Text(message.timestamp, style: .time)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }

        // Message content
        Text(message.content)
          .font(.system(size: 14))
          .textSelection(.enabled)
      }

      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }

  private var avatarColor: Color {
    switch message.role {
    case .user:
      return .blue
    case .assistant:
      return .green
    case .tool:
      return .orange
    }
  }

  private var avatarInitial: String {
    switch message.role {
    case .user:
      return "U"
    case .assistant:
      return "A"
    case .tool:
      return "T"
    }
  }

  private var roleTitle: String {
    switch message.role {
    case .user:
      return "User"
    case .assistant:
      return "Assistant"
    case .tool:
      return "Tool Result"
    }
  }
}
```

### Example/MCPClientChat/MCPClientChat/Chat/UI/ChatView.swift
```swift
//
//  ChatView.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import SwiftUI
import MCPClient

struct ChatView: View {
  @EnvironmentObject var anthropicManager: AnthropicNonStreamManager
  @EnvironmentObject var openAIManager: OpenAIChatNonStreamManager

  @State private var inputText = ""
  @State private var selectedProvider: AIProvider = .anthropic
  @State private var selectedMCPServer: MCPServerType = .github
  @State private var mcpClient: MCPClient?
  @State private var isConnecting = false
  @State private var connectionError: String?

  enum AIProvider: String, CaseIterable {
    case anthropic = "Anthropic"
    case openai = "OpenAI"
  }

  enum MCPServerType: String, CaseIterable {
    case github = "GitHub"
    case claudeCode = "Claude Code"
  }

  private var currentManager: ChatManager {
    selectedProvider == .anthropic ? anthropicManager : openAIManager
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header with controls
      headerView

      Divider()

      // Messages
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(currentManager.messages) { message in
              ChatMessageView(message: message)
                .id(message.id)
            }

            if currentManager.isLoading {
              HStack {
                ProgressView()
                  .scaleEffect(0.7)
                Text("Thinking...")
                  .font(.system(size: 12))
                  .foregroundColor(.secondary)
              }
              .padding()
              .id("loading")
            }
          }
        }
        .onChange(of: currentManager.messages.count) { _, _ in
          withAnimation {
            if currentManager.isLoading {
              proxy.scrollTo("loading", anchor: .bottom)
            } else if let lastMessage = currentManager.messages.last {
              proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
        }
      }

      Divider()

      // Input
      ChatInputView(
        inputText: $inputText,
        onSend: sendMessage,
        isLoading: currentManager.isLoading
      )
    }
    .frame(minWidth: 600, minHeight: 400)
  }

  private var headerView: some View {
    HStack {
      // AI Provider Picker
      Picker("Provider", selection: $selectedProvider) {
        ForEach(AIProvider.allCases, id: \.self) { provider in
          Text(provider.rawValue).tag(provider)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .frame(width: 200)
      .onChange(of: selectedProvider) { _, _ in
        setupManagerWithClient()
      }

      Divider()
        .frame(height: 20)

      // MCP Server Picker
      Picker("MCP Server", selection: $selectedMCPServer) {
        ForEach(MCPServerType.allCases, id: \.self) { server in
          Text(server.rawValue).tag(server)
        }
      }
      .pickerStyle(MenuPickerStyle())
      .frame(width: 150)

      // Connect Button
      Button(action: connectToMCPServer) {
        if isConnecting {
          ProgressView()
            .scaleEffect(0.5)
        } else {
          Text(mcpClient != nil ? "Reconnect" : "Connect")
        }
      }
      .disabled(isConnecting)

      // Connection Status
      if let client = mcpClient {
        Circle()
          .fill(Color.green)
          .frame(width: 8, height: 8)
        Text("Connected")
          .font(.system(size: 11))
          .foregroundColor(.secondary)
      } else if let error = connectionError {
        Text(error)
          .font(.system(size: 11))
          .foregroundColor(.red)
      }

      Spacer()

      // Clear button
      Button("Clear") {
        currentManager.clearMessages()
      }
    }
    .padding()
  }

  private func connectToMCPServer() {
    Task {
      isConnecting = true
      connectionError = nil

      do {
        switch selectedMCPServer {
        case .github:
          mcpClient = try await GithubMCPClient.create()
        case .claudeCode:
          mcpClient = try await ClaudeCodeMCPClient.create()
        }

        setupManagerWithClient()

        currentManager.appendMessage(ChatMessage(
          role: .assistant,
          content: "Connected to \(selectedMCPServer.rawValue) MCP server. Tools are now available."
        ))

      } catch {
        connectionError = error.localizedDescription
        mcpClient = nil
      }

      isConnecting = false
    }
  }

  private func setupManagerWithClient() {
    guard let client = mcpClient else { return }

    currentManager.setClient(client)

    Task {
      do {
        try await currentManager.setupTools()
      } catch {
        currentManager.appendMessage(ChatMessage(
          role: .assistant,
          content: "Failed to setup tools: \(error.localizedDescription)"
        ))
      }
    }
  }

  private func sendMessage() {
    let message = inputText
    inputText = ""

    currentManager.appendMessage(ChatMessage(role: .user, content: message))

    Task {
      await currentManager.sendMessage(message)
    }
  }
}

#Preview {
  ChatView()
}
```

### Example/MCPClientChat/MCPClientChat/MCP/Clients/ClaudeCodeMCPClient.swift
```swift
//
//  ClaudeCodeMCPClient.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import MCPClient
import Foundation

struct ClaudeCodeMCPClient {
  static func create() async throws -> MCPClient {
    // Note: This is a hypothetical Claude Code MCP server
    // Replace with actual server details when available
    try await MCPClient(
      info: .init(name: "ClaudeCodeMCPClient", version: "1.0.0"),
      transport: .stdioProcess(
        "npx",
        args: ["-y", "@modelcontextprotocol/server-claude-code"], // Hypothetical package
        verbose: true),
      capabilities: .init()
    )
  }
}
```

### Example/MCPClientChat/MCPClientChat/MCP/Clients/GithubMCPClient.swift
```swift
//
//  GithubMCPClient.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import MCPClient
import Foundation

struct GithubMCPClient {
  static func create() async throws -> MCPClient {
    try await MCPClient(
      info: .init(name: "GithubMCPClient", version: "1.0.0"),
      transport: .stdioProcess(
        "npx",
        args: ["-y", "@modelcontextprotocol/server-github"],
        verbose: true),
      capabilities: .init()
    )
  }
}
```

### Example/MCPClientChat/MCPClientChat.xcodeproj/project.pbxproj
```
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {

/* Begin PBXBuildFile section */
		C02D5F992D7C3C250016FFA3 /* MCPSwiftWrapper in Frameworks */ = {isa = PBXBuildFile; productRef = C02D5F982D7C3C250016FFA3 /* MCPSwiftWrapper */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		C02D5F772D7C3B860016FFA3 /* MCPClientChat.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MCPClientChat.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		C02D5F792D7C3B860016FFA3 /* MCPClientChat */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = MCPClientChat;
			sourceTree = "<group>";
		};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		C02D5F742D7C3B860016FFA3 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				C02D5F992D7C3C250016FFA3 /* MCPSwiftWrapper in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		C02D5F6E2D7C3B860016FFA3 = {
			isa = PBXGroup;
			children = (
				C02D5F792D7C3B860016FFA3 /* MCPClientChat */,
				C02D5F782D7C3B860016FFA3 /* Products */,
			);
			sourceTree = "<group>";
		};
		C02D5F782D7C3B860016FFA3 /* Products */ = {
			isa = PBXGroup;
			children = (
				C02D5F772D7C3B860016FFA3 /* MCPClientChat.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		C02D5F762D7C3B860016FFA3 /* MCPClientChat */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = C02D5F862D7C3B870016FFA3 /* Build configuration list for PBXNativeTarget "MCPClientChat" */;
			buildPhases = (
				C02D5F732D7C3B860016FFA3 /* Sources */,
				C02D5F742D7C3B860016FFA3 /* Frameworks */,
				C02D5F752D7C3B860016FFA3 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				C02D5F792D7C3B860016FFA3 /* MCPClientChat */,
			);
			name = MCPClientChat;
			packageProductDependencies = (
				C02D5F982D7C3C250016FFA3 /* MCPSwiftWrapper */,
			);
			productName = MCPClientChat;
			productReference = C02D5F772D7C3B860016FFA3 /* MCPClientChat.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		C02D5F6F2D7C3B860016FFA3 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {
					C02D5F762D7C3B860016FFA3 = {
						CreatedOnToolsVersion = 16.0;
					};
				};
			};
			buildConfigurationList = C02D5F722D7C3B860016FFA3 /* Build configuration list for PBXProject "MCPClientChat" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = C02D5F6E2D7C3B860016FFA3;
			minimizedProjectReferenceProxies = 1;
			packageReferences = (
				C02D5F952D7C3BFA0016FFA3 /* XCLocalSwiftPackageReference "../.." */,
			);
			preferredProjectObjectVersion = 77;
			productRefGroup = C02D5F782D7C3B860016FFA3 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				C02D5F762D7C3B860016FFA3 /* MCPClientChat */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		C02D5F752D7C3B860016FFA3 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		C02D5F732D7C3B860016FFA3 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		C02D5F842D7C3B870016FFA3 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.5;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		C02D5F852D7C3B870016FFA3 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.5;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
			};
			name = Release;
		};
		C02D5F872D7C3B870016FFA3 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = MCPClientChat/MCPClientChat.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"MCPClientChat/Preview Content\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = io.bairesdev.MCPClientChat;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
			};
			name = Debug;
		};
		C02D5F882D7C3B870016FFA3 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = MCPClientChat/MCPClientChat.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"MCPClientChat/Preview Content\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = io.bairesdev.MCPClientChat;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCBuildConfigurationList section */
		C02D5F722D7C3B860016FFA3 /* Build configuration list for PBXProject "MCPClientChat" */ = {
			isa = XCBuildConfigurationList;
			buildConfigurations = (
				C02D5F842D7C3B870016FFA3 /* Debug */,
				C02D5F852D7C3B870016FFA3 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		C02D5F862D7C3B870016FFA3 /* Build configuration list for PBXNativeTarget "MCPClientChat" */ = {
			isa = XCBuildConfigurationList;
			buildConfigurations = (
				C02D5F872D7C3B870016FFA3 /* Debug */,
				C02D5F882D7C3B870016FFA3 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCBuildConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		C02D5F952D7C3BFA0016FFA3 /* XCLocalSwiftPackageReference "../.." */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = ../..;
		};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		C02D5F982D7C3C250016FFA3 /* MCPSwiftWrapper */ = {
			isa = XCSwiftPackageProductDependency;
			package = C02D5F952D7C3BFA0016FFA3 /* XCLocalSwiftPackageReference "../.." */;
			productName = MCPSwiftWrapper;
		};
/* End XCSwiftPackageProductDependency section */
	};
	rootObject = C02D5F6F2D7C3B860016FFA3 /* Project object */;
}
```