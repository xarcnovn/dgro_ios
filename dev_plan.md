## iOS MCP Client MVP Implementation Plan (Anthropic-Only with HTTP Streaming)

### Overview
Create a minimal iOS app that connects to remote MCP servers via HTTP streaming transport (Server-Sent Events), focusing exclusively on Anthropic integration for the MVP.

### Core Architecture Principles
- **REUSE EVERYTHING**: MCPSwiftWrapper already has all needed functionality
- **HTTPClientTransport**: Use built-in streaming HTTP transport (not WebSocket)
- **Anthropic-Only**: Remove OpenAI components for MVP simplicity
- **KISS/DRY**: Don't reinvent any existing functionality

### Phase 1: Update Package Dependencies
1. **Update Package.swift** to support iOS platform:
   ```swift
   platforms: [
     .macOS(.v14),
     .iOS(.v16)  // Add iOS 16+ support
   ]
   ```

2. **Verify dependencies support iOS**:
   - mcp-swift-sdk: ✅ Already supports iOS 16.0+
   - SwiftAnthropic: ✅ Should work on iOS
   - Remove SwiftOpenAI from iOS target (MVP doesn't need it)

### Phase 2: Create iOS App Structure
```
MCPiOSClient/
├── MCPiOSClientApp.swift          // App entry point
├── Views/
│   ├── ChatView.swift             // Main chat interface
│   ├── ChatInputView.swift        // iOS-optimized input
│   ├── ChatMessageView.swift      // Message display
│   └── ServerConfigView.swift     // MCP server URL config
├── Models/
│   └── AnthropicChatManager.swift // Adapted from existing
└── Info.plist                      // Network permissions
```

### Phase 3: MCP Connection Implementation
1. **HTTPClientTransport Usage** (from mcp_swift_sdk.md):
   ```swift
   let transport = HTTPClientTransport(
       endpoint: URL(string: "http://your-mcp-server:8080")!,
       streaming: true  // Enable SSE for real-time updates
   )
   let client = try await MCPClient(
       info: .init(name: "MCPiOSClient", version: "1.0.0"),
       transport: transport,
       capabilities: .init()
   )
   ```

2. **Server Configuration Storage**:
   - Store MCP server URL in UserDefaults
   - Store Anthropic API key in Keychain (secure)
   - Allow user to configure server endpoint

### Phase 4: Core Components

1. **MCPiOSClientApp.swift**:
   - Initialize AnthropicService with API key from Keychain
   - Set up @StateObject for chat manager
   - Handle app lifecycle

2. **AnthropicChatManager.swift** (adapt existing):
   - Reuse existing AnthropicNonStreamManager logic
   - Replace stdioProcess with HTTPClientTransport
   - Keep tool discovery/execution as-is

3. **ChatView.swift** (iOS-specific adaptations):
   - NavigationStack for iOS 16+
   - Proper keyboard handling with .scrollDismissesKeyboard(.interactively)
   - Safe area management
   - iOS-native styling

4. **ServerConfigView.swift** (new):
   - Text field for MCP server URL
   - Secure field for Anthropic API key
   - Connection test button
   - Save to UserDefaults/Keychain

### Phase 5: iOS UI Adaptations
1. **Keyboard handling**:
   - Use .keyboardType(.default)
   - Implement keyboard avoidance
   - Add .submitLabel(.send)

2. **iOS-specific styling**:
   - Color(.systemBackground) instead of .controlBackgroundColor
   - .listStyle(PlainListStyle())
   - Proper safe area handling

3. **Touch optimizations**:
   - Larger touch targets (44pt minimum)
   - Haptic feedback for actions
   - Pull-to-refresh for messages

### Phase 6: Info.plist Configuration
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>  <!-- For development; restrict in production -->
</dict>
```

### Phase 7: Implementation Steps

1. **Create iOS app target**:
   ```bash
   - Add new iOS app target "MCPiOSClient"
   - Target iOS 16.0+
   - SwiftUI interface
   ```

2. **Copy and adapt core files**:
   - Copy MCPTool+AnthropicTool.swift (no changes needed)
   - Copy AnthropicNonStreamManager.swift (minor adaptations)
   - Copy chat UI components (iOS-specific changes)

3. **Implement MCP connection**:
   ```swift
   // In ServerConfigView
   @State private var serverURL = "http://localhost:3000"
   @State private var mcpClient: MCPClient?

   func connectToServer() async {
       let transport = HTTPClientTransport(
           endpoint: URL(string: serverURL)!,
           streaming: true
       )
       mcpClient = try await MCPClient(
           info: .init(name: "MCPiOSClient", version: "1.0.0"),
           transport: transport,
           capabilities: .init()
       )
   }
   ```

4. **Integrate with Anthropic**:
   - Reuse existing anthropicTools() method
   - Reuse existing anthropicCallTool() method
   - No changes to tool conversion logic

### Key Differences from macOS Version
| Component | macOS | iOS MVP |
|-----------|--------|---------|
| Transport | stdio (local process) | HTTP streaming (remote server) |
| Server | Spawns via npx | Connects to existing HTTP server |
| Platform | macOS 14+ | iOS 16+ |
| UI | macOS controls | iOS-native components |
| Storage | Local | UserDefaults + Keychain |

### MVP Success Criteria
1. ✅ Connect to remote MCP server via HTTP
2. ✅ Discover available tools
3. ✅ Chat with Anthropic Claude
4. ✅ Execute MCP tools through chat
5. ✅ Display results in iOS-native UI

### What's NOT in MVP
- ❌ OpenAI support (Anthropic only)
- ❌ Multiple server connections
- ❌ Local MCP server spawning
- ❌ Advanced error recovery
- ❌ iPad-specific layouts

### Validation Against Documentation
- **mcp_swift_sdk.md**: Using HTTPClientTransport exactly as documented
- **mcp_docs.md**: Following streamable HTTP transport specification with SSE
- **swift_mcp_client.md**: Reusing all MCPSwiftWrapper functionality

This plan follows KISS/DRY principles by maximizing reuse of existing code and using built-in SDK capabilities rather than creating custom solutions.