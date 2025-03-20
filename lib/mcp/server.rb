require 'json'
require 'logger'

module MCP
  class Server
    attr_reader :name, :version, :tools

    def initialize(name, version = "1.0.0")
      @name = name
      @version = version
      @tools = {}
      @logger = Logger.new(STDERR)
      @logger.level = Logger::INFO
    end

    def register_tool(tool)
      @tools[tool.name] = tool
      @logger.info("Registered tool: #{tool.name}")
    end

    def run(transport = Transport::Stdio.new)
      @logger.info("Starting MCP server: #{@name} v#{@version}")
      
      transport.on_message do |message|
        handle_message(message)
      end
      
      transport.start
    end

    private

    def handle_message(message)
      @logger.debug("Received message: #{message}")
      begin
        parsed = JSON.parse(message)
      rescue JSON::ParserError => e
        @logger.error("Failed to parse JSON: #{e.message}")
        return error_response(nil, -32700, "Parse error: #{e.message}")
      end
      
      if !parsed['jsonrpc'] || parsed['jsonrpc'] != '2.0'
        @logger.warn("Invalid JSON-RPC version: #{parsed['jsonrpc']}")
        return error_response(parsed['id'], -32600, "Invalid Request: Expected jsonrpc 2.0")
      end

      case parsed['method']
      when 'initialize'
        response = handle_initialize(parsed)
        # After initialize, send 'initialized' notification
        if response
          send_initialized_notification
        end
        return response
      when 'initialized'
        # Client sends this notification, we don't need to respond
        @logger.info("Received initialized notification from client")
        return nil
      when 'tools/list'
        handle_list_tools(parsed)
      when 'tools/call'
        handle_call_tool(parsed)
      else
        error_response(parsed['id'], -32601, "Method not found: #{parsed['method']}")
      end
    end

    def handle_initialize(request)
      client_protocol_version = request['params']['protocolVersion']
      @logger.info("Initializing MCP server with protocol version: #{client_protocol_version}")
      
      # プロトコルバージョンをクライアントと合わせる
      protocol_version = client_protocol_version || "2024-11-05"
      
      response = {
        jsonrpc: '2.0',
        id: request['id'],
        result: {
          serverInfo: {
            name: @name,
            version: @version
          },
          capabilities: {
            tools: {}
          },
          protocolVersion: protocol_version
        }
      }
      
      JSON.generate(response)
    end

    def send_initialized_notification
      notification = {
        jsonrpc: '2.0',
        method: 'initialized',
        params: {}
      }
      
      @logger.info("Sending initialized notification")
      notif_json = JSON.generate(notification)
      @logger.debug("Notification JSON: #{notif_json}")
      STDOUT.puts(notif_json)
      STDOUT.flush
    end

    def handle_list_tools(request)
      tool_list = @tools.values.map do |tool|
        {
          name: tool.name,
          description: tool.description,
          inputSchema: tool.input_schema
        }
      end

      response = {
        jsonrpc: '2.0',
        id: request['id'],
        result: {
          tools: tool_list
        }
      }
      
      JSON.generate(response)
    end

    def handle_call_tool(request)
      tool_name = request['params']['name']
      arguments = request['params']['arguments'] || {}
      
      if !@tools.key?(tool_name)
        return error_response(request['id'], -32601, "Tool not found: #{tool_name}")
      end

      begin
        result = @tools[tool_name].execute(arguments)
        
        response = {
          jsonrpc: '2.0',
          id: request['id'],
          result: {
            content: [
              {
                type: "text",
                text: result.to_s
              }
            ]
          }
        }
        
        JSON.generate(response)
      rescue => e
        error_response(request['id'], -32603, "Tool execution error: #{e.message}")
      end
    end

    def error_response(id, code, message)
      response = {
        jsonrpc: '2.0',
        id: id,
        error: {
          code: code,
          message: message
        }
      }
      
      JSON.generate(response)
    end
  end
end