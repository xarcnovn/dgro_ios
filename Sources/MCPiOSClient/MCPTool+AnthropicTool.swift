//
//  MCPTool+AnthropicTool.swift
//  MCPiOSClient
//
//  Adapted from MCPSwiftWrapper
//

import Foundation
import MCPClient
import SwiftAnthropic

// MARK: - Anthropic conversions

extension MCPClient {

  /// Returns an array of Anthropic tools by converting MCP tools.
  public func anthropicTools() async throws -> [MessageParameter.Tool] {
    let tools = try await self.listTools()
    return tools.compactMap { $0.anthropicTool() }
  }

  /// Calls an MCP tool with the given name and arguments and returns the result.
  /// - Parameters:
  ///   - name: The name of the tool to call
  ///   - arguments: The arguments to pass to the tool as an Encodable object
  /// - Returns: The result of the tool call as an AnthropicMessage.Content
  /// - Throws: If the tool call fails or returns an error
  public func anthropicCallTool<T: Encodable>(name: String, arguments: T) async throws -> MessageParameter.Message.Content {
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
  func anthropicTool() -> MessageParameter.Tool? {

    let inputSchema = self.inputSchema

    // Parse the JSON schema
    guard let schemaData = try? JSONSerialization.data(withJSONObject: inputSchema),
          let schema = try? JSONDecoder().decode(JSONSchema.self, from: schemaData) else {
      return nil
    }

    // Convert to Anthropic's input schema format
    let anthropicInputSchema = schema.toAnthropicInputSchema()

    return MessageParameter.Tool(
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

  func toAnthropicInputSchema() -> MessageParameter.Tool.InputSchema {
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