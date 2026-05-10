module McpTools
  class StartCycleTool < MCP::Tool
    tool_name "start_color_cycle"
    description "照明の色を一定間隔でゆっくり変化させるサイクルモードを開始する。"
    input_schema(
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
    )

    class << self
      def call(interval: 5, brightness: 80, server_context:)
        HueCycler.start(interval: interval, brightness: brightness)
        MCP::Tool::Response.new([{
          type: "text",
          text: "サイクル始めたよ！#{interval}秒ごとに色が変わるよ"
        }])
      end
    end
  end
end
