module McpTools
  class TurnOffTool < MCP::Tool
    tool_name "turn_off_lights"
    description "部屋の照明を消す。"
    input_schema(properties: {})

    class << self
      def call(server_context:, **_args)
        HueCycler.kill
        result = HueService.turn_off
        MCP::Tool::Response.new([{
          type: "text",
          text: "消したよ！#{result.is_a?(Hash) && result[:mock] ? " [mock]" : ""}"
        }])
      end
    end
  end
end
