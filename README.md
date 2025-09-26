# MCP iOS Client MVP

A minimal iOS client for the Model Context Protocol (MCP), featuring Anthropic Claude integration with HTTP streaming transport.

## Features

- ✅ Connect to remote MCP servers via HTTP streaming (Server-Sent Events)
- ✅ Anthropic Claude integration for natural language interaction
- ✅ Automatic MCP tool discovery and execution
- ✅ iOS-optimized UI with proper keyboard handling
- ✅ Secure API key storage

## Architecture

This iOS app connects to MCP servers running on remote machines via HTTP transport with streaming support. Unlike the macOS version which spawns local processes, the iOS app uses `HTTPClientTransport` to connect to existing MCP servers.

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 6.0+
- An MCP server running with HTTP transport exposed
- Anthropic API key

## Project Structure

```
MCPiOSClient/
├── Package.swift                    # Swift Package Manager configuration
├── Sources/MCPiOSClient/            # Core MCP functionality
│   └── MCPTool+AnthropicTool.swift # MCP to Anthropic tool conversion
├── MCPiOSClientApp/                 # iOS App
│   ├── MCPiOSClientApp.swift       # App entry point
│   ├── Models/
│   │   ├── ChatMessage.swift       # Message model
│   │   └── AnthropicChatManager.swift # Chat & MCP manager
│   ├── Views/
│   │   ├── ChatView.swift          # Main chat interface
│   │   ├── ChatInputView.swift     # Message input
│   │   ├── ChatMessageView.swift   # Message display
│   │   └── ServerConfigView.swift  # Server configuration
│   └── Info.plist                   # App configuration
└── project.yml                      # XcodeGen configuration
```

## Setup Instructions

### 1. Clone and Open in Xcode

```bash
# Clone the repository
git clone <repository-url>
cd ios_mcp_clean_2609

# Open in Xcode
open Package.swift
```

Xcode will automatically resolve the dependencies:
- `mcp-swift-sdk` - Official MCP Swift SDK
- `SwiftAnthropic` - Anthropic API client

### 2. Set Up an MCP Server

You need an MCP server running with HTTP transport. Example using the GitHub MCP server:

```bash
# Install the MCP server
npm install -g @modelcontextprotocol/server-github

# Create a server wrapper that exposes HTTP transport
# Save this as mcp-http-server.js
```

```javascript
// mcp-http-server.js
const express = require('express');
const { spawn } = require('child_process');
const app = express();

app.use(express.json());

// Configure your MCP server command here
const mcpServer = spawn('npx', ['@modelcontextprotocol/server-github'], {
  env: { ...process.env, GITHUB_TOKEN: 'your-github-token' }
});

app.post('/mcp', (req, res) => {
  // Handle MCP messages
  mcpServer.stdin.write(JSON.stringify(req.body) + '\n');

  mcpServer.stdout.once('data', (data) => {
    res.json(JSON.parse(data.toString()));
  });
});

// SSE endpoint for streaming
app.get('/mcp/stream', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  });

  mcpServer.stdout.on('data', (data) => {
    res.write(`data: ${data}\n\n`);
  });
});

app.listen(3000, () => {
  console.log('MCP HTTP server running on http://localhost:3000');
});
```

### 3. Run the iOS App

#### Using Xcode:
1. Open `Package.swift` in Xcode
2. Select the MCPiOSClient scheme
3. Choose an iOS Simulator (iPhone 14 or later recommended)
4. Press Cmd+R to run

#### Using XcodeGen (if installed):
```bash
# Generate Xcode project
xcodegen generate

# Open generated project
open MCPiOSClient.xcodeproj
```

### 4. Configure the App

When the app launches:

1. Tap the gear icon or "Not connected" banner
2. Enter your MCP server URL (e.g., `http://localhost:3000`)
3. Enter your Anthropic API key
4. Tap "Connect"

## Usage

Once connected:
- The app will display available MCP tools
- Type messages to interact with Claude
- Claude will automatically use MCP tools when appropriate
- Tool results are displayed inline in the chat

## Development Notes

### Key Implementation Details

- **Transport**: Uses `HTTPClientTransport` with streaming enabled for SSE
- **No Process Spawning**: iOS apps cannot spawn external processes
- **API Key Security**: Store in iOS Keychain for production
- **Network Permissions**: Info.plist configured for HTTP connections

### Differences from macOS Version

| Feature | macOS | iOS |
|---------|-------|-----|
| MCP Server | Local process via stdio | Remote via HTTP |
| Transport | StdioTransport | HTTPClientTransport |
| Server Management | Spawns npm packages | Connects to existing servers |
| Sandboxing | Disabled | Enabled (iOS default) |

## Troubleshooting

### Connection Issues
- Ensure MCP server is running and accessible
- Check that the URL is correct (include http:// or https://)
- For local development, use your Mac's IP address instead of localhost

### Build Issues
- Clean build folder: Cmd+Shift+K
- Reset package caches: File > Packages > Reset Package Caches
- Ensure Xcode 15+ is installed

### Runtime Issues
- Check console logs in Xcode for detailed error messages
- Verify Anthropic API key is valid
- Ensure MCP server supports HTTP transport

## Security Considerations

⚠️ **For Development Only**: The current configuration allows arbitrary HTTP connections. For production:
1. Use HTTPS exclusively
2. Implement proper certificate pinning
3. Store API keys in iOS Keychain
4. Restrict NSAppTransportSecurity to specific domains

## Next Steps

- [ ] Add Keychain integration for secure API key storage
- [ ] Implement connection retry logic
- [ ] Add support for multiple MCP servers
- [ ] Create custom MCP server implementations
- [ ] Add OpenAI support (currently Anthropic only)

## License

MIT

## Acknowledgments

Built using:
- [MCP Swift SDK](https://github.com/modelcontextprotocol/mcp-swift-sdk)
- [SwiftAnthropic](https://github.com/jamesrochabrun/SwiftAnthropic)
- Model Context Protocol specification