# MCP Ruby Server Skeleton

> Acknowledgment: This implementation was inspired by the article [Building a Model Context Protocol Server with TypeScript](https://azukiazusa.dev/blog/typescript-mcp-server/) by Azuki Azusa.

This project is a Ruby implementation of a Model Context Protocol (MCP) server skeleton. It provides an interface that allows Large Language Models (LLMs) like Claude to call tools. The current implementation provides a tool that generates random numbers.

## Features

- `get-random-number`: Generates a random integer between 1 and a specified maximum value (defaults to 100)
- MCP protocol version 2024-11-05 compatibility
- Detailed logging for debugging
- JSON-RPC 2.0 compliant message handling

## Requirements

- Ruby 3.0+

## Architecture and Design

This server consists of the following components:

### Core Components

- `MCP::Server`: Main server implementation that handles MCP protocol messages
  - Protocol initialization
  - Tool registration and management
  - Message handling
  - Tool listing and execution
  - Error handling

- `MCP::Transport::Stdio`: Standard I/O transport layer for communication
  - Message reception
  - Response transmission
  - Event-driven message handling

- `MCP::Tool`: Tool definition and execution handler
  - Management of tool name, description, and input schema
  - Tool logic implementation
  - Argument processing during execution

- `RandomNumberServer`: Server implementation that registers and manages tools
  - Server initialization
  - Tool setup
  - Server execution

### Protocol Flow

The server follows the MCP initialization protocol:

1. Client sends an `initialize` request with protocol version
2. Server responds with its capabilities and matches the protocol version
3. Server sends an `initialized` notification
4. Client can then list and call tools

### Implemented MCP APIs

The server implements the following MCP APIs:

- `initialize`: Server initialization and protocol version negotiation
- `tools/list`: Lists available tools and their schemas
- `tools/call`: Executes a tool with provided arguments

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd mcp-ruby-skeleton
```

Make sure the server script is executable:

```bash
chmod +x bin/run_server.rb
```

## Usage

### Direct Execution

Run the server directly:

```bash
./bin/run_server.rb
```

### Integration with Claude Desktop

Add the following to your Claude Desktop configuration at:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "random-number": {
      "command": "ruby",
      "args": [
        "/Users/bash/src/mcp-ruby-skeleton/bin/run_server.rb"
      ]
    }
  }
}
```

Replace the path with the absolute path to your `run_server.rb` file on your system.

After configuring, restart Claude Desktop and try a prompt like "Generate a random number between 1 and 50."

## Debugging

### Logs

Claude app logs related to MCP servers are available at:
- macOS: `~/Library/Logs/Claude/mcp*.log`
- Windows: `%APPDATA%\Claude\logs\mcp*.log`

To view the logs in real-time:

```bash
# On macOS
tail -f ~/Library/Logs/Claude/mcp*.log

# On Windows
type "%APPDATA%\Claude\logs\mcp*.log"
```

The server itself logs to standard error output (STDERR), and the log level is set during the initialization of the `RandomNumberServer` class (currently at DEBUG level).

### Common Issues

**Server disconnection**  
If you see a message like "MCP server disconnected", check:
- Protocol version compatibility
- JSON-RPC message formatting
- Proper initialization sequence
- File permissions on the server script

**Tool not showing up**  
If the random number tool doesn't appear in Claude:
- Check that the server is properly registered in the config file
- Ensure the server script has execution permission
- Restart Claude Desktop completely
- Check the logs for any errors

## Development

### Adding New Tools

You can add more tools to the server by modifying the `RandomNumberServer` class:

```ruby
def setup_tools
  # Existing random number tool
  random_number_tool = MCP::Tool.new(
    "get-random-number",
    "Generate a random number between 1 and the specified maximum value",
    {
      type: "object",
      properties: {
        max: {
          type: "integer",
          description: "Maximum value for the random number (defaults to 100 if not specified)"
        }
      }
    }
  ) do |args|
    max = (args["max"] || 100).to_i
    max = 100 if max <= 0
    
    rand(1..max)
  end

  @server.register_tool(random_number_tool)
  
  # Add your new tool here
  new_tool = MCP::Tool.new(
    "tool-name",
    "Tool description",
    {
      type: "object",
      properties: {
        # Tool parameters
      }
    }
  ) do |args|
    # Tool implementation
  end
  
  @server.register_tool(new_tool)
end
```

### Testing

When implementing new tools or server features, it's recommended to add tests. Testing should combine unit tests, integration tests, and end-to-end tests.

Tests should verify:
- Proper definition and registration of tools
- Correct protocol handling
- Error handling
- Input validation
- Expected output confirmation

### Error Handling and Exceptions

To improve the robustness of the MCP server, it's important to implement proper error handling and exception handling:

1. Appropriately catch exceptions during tool execution and return meaningful error messages to clients
2. Validate invalid input parameters
3. Properly handle network and I/O errors
4. Consider timeouts and resource limitations
