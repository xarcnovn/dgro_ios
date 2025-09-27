//
//  MCPTool+AnthropicTool.swift
//  MCPiOSClient
//
//  Adapted from MCPSwiftWrapper
//

import Foundation
import MCP
import SwiftAnthropic

// MARK: - Anthropic conversions

// Add helper for Value type
extension Value {
  init?(anyValue: Any) {
    if let str = anyValue as? String {
      self = .string(str)
    } else if let bool = anyValue as? Bool {
      self = .bool(bool)
    } else if let int = anyValue as? Int {
      self = .int(int)
    } else if let double = anyValue as? Double {
      self = .double(double)
    } else if let dict = anyValue as? [String: Any] {
      let values = dict.compactMapValues { Value(anyValue: $0) }
      self = .object(values)
    } else if let array = anyValue as? [Any] {
      let values = array.compactMap { Value(anyValue: $0) }
      self = .array(values)
    } else {
      return nil
    }
  }
}

extension Client {

  /// Returns an array of Anthropic tools by converting MCP tools.
  public func anthropicTools() async throws -> [MessageParameter.Tool] {
    let (tools, _) = try await self.listTools()
    return tools.compactMap { $0.anthropicTool() }
  }

  /// Calls an MCP tool with the given name and arguments and returns the result.
  /// - Parameters:
  ///   - name: The name of the tool to call
  ///   - arguments: The arguments to pass to the tool as an Encodable object
  /// - Returns: The result of the tool call as ContentObject array
  /// - Throws: If the tool call fails or returns an error
  public func anthropicCallTool<T: Encodable>(name: String, arguments: T) async throws -> [MessageParameter.Message.Content.ContentObject] {
    // Convert arguments to Value dictionary
    let data = try JSONEncoder().encode(arguments)
    let json = try JSONSerialization.jsonObject(with: data)
    let valueArgs = (json as? [String: Any]).map { dict in
      dict.compactMapValues { Value(anyValue: $0) }
    }

    let result = try await self.callTool(name: name, arguments: valueArgs)

    // Check if result has isError flag
    if let isError = result.isError, isError {
      throw MCPToolError.callFailed(result.content)
    }

    // Convert Tool.Content to MessageParameter.Message.Content.ContentObject
    return result.content.compactMap { content in
      switch content {
      case .text(let text):
        return .text(text)
      case .image(let data, let mimeType, _):
        // Convert to ImageSource for images - using default JPEG type
        // Note: MCP doesn't specify image type, so we default to JPEG
        let imageSource = MessageParameter.Message.Content.ImageSource(
          type: .base64,
          mediaType: .jpeg,
          data: data
        )
        return .image(imageSource)
      case .resource(_, _, let text):
        // Convert resource to text representation if available
        if let text = text {
          return .text(text)
        }
        return nil
      case .audio:
        // Audio not supported in Anthropic messages
        return nil
      }
    }
  }
}

extension Tool {
  /// Converts an MCP Tool to an Anthropic Tool format
  func anthropicTool() -> MessageParameter.Tool? {

    let inputSchema = self.inputSchema

    // Parse the JSON schema from Value to our intermediate type
    guard let schemaData = try? JSONEncoder().encode(inputSchema),
          let schemaJSON = try? JSONSerialization.jsonObject(with: schemaData),
          let schemaDict = schemaJSON as? [String: Any],
          let reencoded = try? JSONSerialization.data(withJSONObject: schemaDict),
          let schema = try? JSONDecoder().decode(JSONSchema.self, from: reencoded) else {
      return nil
    }

    // Convert to Anthropic's input schema format
    let anthropicInputSchema = schema.toAnthropicInputSchema()

    return .function(
      name: self.name,
      description: self.description,
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

  func toAnthropicInputSchema() -> SwiftAnthropic.JSONSchema {
    // Convert our JSONSchema to SwiftAnthropic's JSONSchema
    var props: [String: SwiftAnthropic.JSONSchema.Property]? = nil

    if let properties = properties {
      props = [:]
      for (key, prop) in properties {
        // Create SwiftAnthropic Property - simplified conversion
        let anthropicProp = SwiftAnthropic.JSONSchema.Property(
          type: prop.type?.toAnthropicType() ?? .string,
          description: prop.description,
          format: prop.format,
          items: nil,
          required: prop.required,
          pattern: prop.pattern,
          const: nil,
          enumValues: prop.enum,
          multipleOf: nil,
          minimum: prop.minimum,
          maximum: prop.maximum,
          minItems: nil,
          maxItems: nil,
          uniqueItems: nil
        )
        props?[key] = anthropicProp
      }
    }

    return SwiftAnthropic.JSONSchema(
      type: .object,
      properties: props,
      required: required,
      pattern: nil,
      const: nil,
      enumValues: nil,
      multipleOf: nil,
      minimum: nil,
      maximum: nil
    )
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

  func toAnthropicType() -> SwiftAnthropic.JSONSchema.JSONType {
    switch self {
    case .string: return .string
    case .number: return .number
    case .integer: return .integer
    case .boolean: return .boolean
    case .array: return .array
    case .object: return .object
    case .null: return .null
    }
  }
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
  case callFailed([Tool.Content])

  var errorDescription: String? {
    switch self {
    case .callFailed(let content):
      let errorTexts = content.compactMap { c -> String? in
        if case .text(let text) = c {
          return text
        }
        return nil
      }
      return "Tool call failed: \(errorTexts.joined(separator: ", "))"
    }
  }
}