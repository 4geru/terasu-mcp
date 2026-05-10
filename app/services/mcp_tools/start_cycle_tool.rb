module McpTools
  module StartCycleTool
    DEFINITION = {
      name: "start_color_cycle",
      description: "照明の色を一定間隔でゆっくり変化させるサイクルモードを開始する。",
      inputSchema: {
        type: "object",
        properties: {
          interval: {
            type: "integer",
            description: "色が変わる間隔（秒）。デフォルト5秒。",
            minimum: 1,
            maximum: 60,
            default: 5
          },
          brightness: {
            type: "integer",
            description: "明るさ (1-100)。デフォルト80。",
            minimum: 1,
            maximum: 100,
            default: 80
          }
        }
      }
    }.freeze

    def self.call(args)
      interval = args["interval"] || 5
      brightness = args["brightness"] || 80
      HueCycler.start(interval: interval, brightness: brightness)
      "サイクル始めたよ！#{interval}秒ごとに色が変わるよ"
    end
  end
end
