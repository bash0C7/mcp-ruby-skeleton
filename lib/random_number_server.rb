require_relative 'mcp/server'
require_relative 'mcp/transport'
require_relative 'mcp/tool'

class RandomNumberServer
  def initialize
    @server = MCP::Server.new("random-number-server", "1.0.0")
    # ログレベルをDEBUGに設定
    @server.instance_variable_get(:@logger).level = Logger::DEBUG
    setup_tools
  end

  def run
    @server.run
  end

  private

  def setup_tools
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
  end
end