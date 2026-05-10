module McpTools
  class SetColorTool < MCP::Tool
    tool_name "set_light_color"
    description "照明の色を変える。"
    input_schema(
      required: ["color"],
      properties: {
        color: {
          type: "string",
          description: "色の名前",
          enum: %w[red yellow warm green blue purple pink]
        }
      }
    )

    class << self
      def call(color:, server_context:)
        result = HueService.set_color(color)
        MCP::Tool::Response.new([{
          type: "text",
          text: "#{color} に変わったよ！#{result.is_a?(Hash) && result[:mock] ? " [mock]" : ""}"
        }])
      end
    end
  end
end
