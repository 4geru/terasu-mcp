module McpTools
  class SetColorCodeTool < MCP::Tool
    tool_name "set_light_color_hex"
    description "照明の色を16進数カラーコード（例: #FF0000）で指定する。"
    input_schema(
      required: ["hex"],
      properties: {
        hex: {
          type: "string",
          description: "16進数カラーコード。例: #FF0000（赤）、#00FFFF（水色）"
        }
      }
    )

    class << self
      def call(hex:, server_context:)
        result = HueService.set_color_hex(hex)
        MCP::Tool::Response.new([{
          type: "text",
          text: "#{hex} に変わったよ！#{result.is_a?(Hash) && result[:mock] ? " [mock]" : ""}"
        }])
      end
    end
  end
end
