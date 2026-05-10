module McpTools
  module SetColorCodeTool
    DEFINITION = {
      name: "set_light_color_hex",
      description: "照明の色を16進数カラーコード（例: #FF0000）で指定する。",
      inputSchema: {
        type: "object",
        required: ["hex"],
        properties: {
          hex: {
            type: "string",
            description: "16進数カラーコード。例: #FF0000（赤）、#00FFFF（水色）"
          }
        }
      }
    }.freeze

    def self.call(args)
      hex = args["hex"]
      result = HueService.set_color_hex(hex)
      "#{hex} に変わったよ！#{result.is_a?(Hash) && result[:mock] ? " [mock]" : ""}"
    end
  end
end
