module MCP
  class Tool
    attr_reader :name, :description, :input_schema

    def initialize(name, description, input_schema, &block)
      @name = name
      @description = description
      @input_schema = input_schema
      @executor = block
    end

    def execute(arguments)
      @executor.call(arguments)
    end
  end
end