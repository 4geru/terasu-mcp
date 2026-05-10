module McpTools
  module SetColorTool
    DEFINITION = {
      name: "set_light_color",
      description: "照明の色を変える。",
      inputSchema: {
        type: "object",
        required: ["color"],
        properties: {
          color: {
            type: "string",
            description: "色の名前",
            enum: %w[red yellow warm green blue purple pink]
          }
        }
      }
    }.freeze

    def self.call(args)
      color = args["color"]
      result = HueService.set_color(color)
      "照明を #{color} に変えました #{result.is_a?(Hash) && result[:mock] ? "[mock]" : ""}"
    end
  end
end
