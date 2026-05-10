module McpTools
  module TurnOffTool
    DEFINITION = {
      name: "turn_off_lights",
      description: "部屋の照明を消す。",
      inputSchema: {
        type: "object",
        properties: {}
      }
    }.freeze

    def self.call(_args)
      result = HueService.turn_off
      "消灯しました #{result.is_a?(Hash) && result[:mock] ? "[mock]" : ""}"
    end
  end
end
