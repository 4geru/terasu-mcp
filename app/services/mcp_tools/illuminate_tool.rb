module McpTools
  class IlluminateTool < MCP::Tool
    tool_name "illuminate"
    description "部屋の照明をつける。明るさと色を指定できる。"
    input_schema(
      properties: {
        brightness: {
          type: "integer",
          description: "明るさ (1-100)",
          minimum: 1,
          maximum: 100,
          default: 80
        },
        color: {
          type: "string",
          description: "色味 (warm / cool)",
          enum: %w[warm cool],
          default: "warm"
        }
      }
    )

    class << self
      def call(brightness: 80, color: "warm", server_context:)
        result = HueService.illuminate(brightness: brightness, color: color)
        MCP::Tool::Response.new([{
          type: "text",
          text: "照らしたよ！(明るさ: #{brightness}%, 色: #{color})#{result.is_a?(Hash) && result[:mock] ? " [mock]" : ""}"
        }])
      end
    end
  end
end
