module McpTools
  module IlluminateTool
    DEFINITION = {
      name: "illuminate",
      description: "部屋の照明をつける。明るさと色を指定できる。",
      inputSchema: {
        type: "object",
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
      }
    }.freeze

    def self.call(args)
      brightness = args["brightness"] || 80
      color      = args["color"] || "warm"
      result = HueService.illuminate(brightness: brightness, color: color)
      "照らしました (明るさ: #{brightness}%, 色: #{color}) #{result.is_a?(Hash) && result[:mock] ? "[mock]" : ""}"
    end
  end
end
