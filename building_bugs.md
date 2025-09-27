# iOS MCP Client Build Errors

## Overview
The iOS MCP Client project has several compilation errors preventing successful building for iOS Simulator. These errors stem from API mismatches between the MCP Swift SDK and SwiftAnthropic library, as well as incorrect type usage.

## Critical Build Errors

### 1. AnthropicChatManager.swift Errors

#### Configuration Type Not Found
**Error:** `cannot find 'Configuration' in scope`
**Location:** AnthropicChatManager.swift:49, 51
**Issue:** The `Configuration` type from MCP SDK is not properly imported or accessible
```swift
// Current (incorrect):
info: Configuration.Info(name: "MCPiOSClient", version: "1.0.0")
capabilities: Configuration.Capabilities()

// Should be:
info: Client.Configuration.Info(...) // or proper namespace
```

#### HTTPClientTransport Type Mismatch
**Error:** `cannot convert value of type 'HTTPClientTransport' to expected argument type 'String'`
**Location:** AnthropicChatManager.swift:50
**Issue:** The Client initializer signature doesn't match - it expects different parameters
```swift
// Current initialization attempt:
mcpClient = try await Client(
    info: Configuration.Info(name: "MCPiOSClient", version: "1.0.0"),
    transport: transport,  // HTTPClientTransport not accepted
    capabilities: Configuration.Capabilities()
)
```

#### Sendable Protocol Violations
**Error:** `non-sendable result type '[MessageParameter.Tool]' cannot be sent from actor-isolated context`
**Location:** AnthropicChatManager.swift:73
**Issue:** SwiftAnthropic types don't conform to Sendable protocol required for async/await across actor boundaries

**Error:** `non-sendable result type 'MessageResponse' cannot be sent from nonisolated context`
**Location:** AnthropicChatManager.swift:113, 219

#### Content Type Mismatches
**Error:** `type 'MessageParameter.Message.Content' has no member 'toolUse'`
**Location:** AnthropicChatManager.swift:194
**Issue:** Incorrect usage of SwiftAnthropic's Content enum
```swift
// Attempting to use:
.toolUse(...)  // This doesn't exist on Content enum
.toolResult(...) // This doesn't exist on Content enum

// Should use Content.ContentObject cases instead
```

#### Tuple Pattern Mismatch
**Error:** `tuple pattern has the wrong length for tuple type 'String'`
**Location:** AnthropicChatManager.swift:168
```swift
// Current (incorrect):
case .text(let text, _):  // Expects 2 values

// Should be:
case .text(let text):  // Only 1 value in enum case
```

### 2. MCPTool+AnthropicTool.swift Errors

#### Value Enum Case Mismatches
**Error:** `type 'Value' has no member 'boolean'` / `type 'Value' has no member 'number'`
**Location:** MCPTool+AnthropicTool.swift:20, 22, 24
**Issue:** MCP SDK's Value enum uses different case names
```swift
// Incorrect:
.boolean(bool)  // Should be: .bool(bool)
.number(double) // Should be: .double(double) or .int(int)
```

#### listTools Return Type Mismatch
**Error:** `value of tuple type '(tools: [Tool], nextCursor: String?)' has no member 'compactMap'`
**Location:** MCPTool+AnthropicTool.swift:42
**Issue:** listTools returns a tuple, not an array
```swift
// Current (incorrect):
let tools = try await self.listTools()
return tools.compactMap { ... }

// Should be:
let (tools, _) = try await self.listTools()
return tools.compactMap { ... }
```

#### ContentObject Type Path Issues
**Error:** `'ContentObject' is not a member type of struct 'SwiftAnthropic.MessageParameter.Message'`
**Location:** MCPTool+AnthropicTool.swift:51
**Issue:** ContentObject is nested under Content enum
```swift
// Incorrect path:
MessageParameter.Message.ContentObject

// Correct path:
MessageParameter.Message.Content.ContentObject
```

#### ImageSource Type Issues
**Error:** `type 'MessageParameter.Message.Content.ContentObject' has no member 'ImageSource'`
**Location:** MCPTool+AnthropicTool.swift:73
**Issue:** ImageSource is at a different nesting level
```swift
// Should be:
MessageParameter.Message.Content.ImageSource
```

### 3. Module and Import Issues

#### MCP Client Import
**Original Error:** `no such module 'MCPClient'`
**Issue:** The module is named 'MCP', not 'MCPClient'
```swift
// Incorrect:
import MCPClient

// Correct:
import MCP
```

#### Missing Type Imports
- Need to import both `MCP` and `MCPiOSClient` in AnthropicChatManager
- Configuration types not accessible without proper imports

### 4. SwiftAnthropic API Misunderstandings

#### Service Factory Parameters
**Error:** `missing argument for parameter 'betaHeaders' in call`
**Location:** AnthropicChatManager.swift:27
```swift
// Missing required parameter:
service = AnthropicServiceFactory.service(apiKey: apiKey)

// Should include:
service = AnthropicServiceFactory.service(apiKey: apiKey, betaHeaders: nil)
```

#### Tool Result Content Structure
The conversion between MCP's Tool.Content and SwiftAnthropic's ContentObject requires careful mapping:
- MCP returns `[Tool.Content]`
- SwiftAnthropic expects `[MessageParameter.Message.Content.ContentObject]`
- Image handling needs proper ImageSource initialization with correct MediaType enum

### 5. Type Conversion Issues

#### JSON Schema Conversion
**Issue:** Converting MCP's `Value` type (for tool schemas) to SwiftAnthropic's `JSONSchema`
- Need to handle different property types
- JSONType enum names don't match between libraries

#### Tool Input Arguments
**Issue:** Converting between different representations of tool arguments
- MCP uses `[String: Value]?`
- SwiftAnthropic uses `MessageResponse.Content.Input` (type alias for `[String: DynamicContent]`)

## Root Causes

1. **API Version Mismatch**: The code appears to be written for different versions of both MCP Swift SDK and SwiftAnthropic than what's installed
2. **Incomplete Type Bridging**: The MCPTool+AnthropicTool extension doesn't properly handle all type conversions
3. **Sendable Conformance**: SwiftAnthropic types aren't designed for use across actor boundaries
4. **Namespace Confusion**: Types are being referenced without proper namespace qualification

## Required Fixes

1. Update all type references to match actual SDK structures
2. Implement proper Sendable wrappers or use `@preconcurrency` imports
3. Fix HTTPClientTransport usage with correct Client initialization
4. Correct all enum case names and type paths
5. Handle all Content type variants properly
6. Add proper error handling for type conversions