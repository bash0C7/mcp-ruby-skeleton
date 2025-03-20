require 'logger'

module MCP
  module Transport
    class Stdio
      def initialize
        @callback = nil
        @logger = Logger.new(STDERR)
        @logger.level = Logger::INFO
      end

      def on_message(&block)
        @callback = block
      end

      def start
        @logger.info("Starting STDIO transport")
        begin
          loop do
            line = STDIN.gets
            if line.nil?
              @logger.info("STDIN closed, exiting")
              break
            end
            
            line = line.strip
            next if line.empty?
            
            @logger.debug("Received: #{line}")
            response = @callback.call(line) if @callback
            if response
              @logger.debug("Sending response: #{response}")
              STDOUT.puts(response)
              STDOUT.flush
            else
              @logger.debug("No response needed for this message (likely a notification)")
            end
          end
        rescue => e
          @logger.error("Error in STDIO transport: #{e.message}")
          @logger.error(e.backtrace.join("\n"))
          raise
        end
      end
    end
  end
end