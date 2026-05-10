module McpTools
  class StartBreathingTool < MCP::Tool
    tool_name "start_breathing"
    description "照明の明るさがゆっくり上下する呼吸モードを開始する。色は固定。"
    input_schema(
      properties: {
        color: {
          type: "string",
          description: "色の名前。デフォルトは blue。",
          enum: %w[red yellow warm green blue purple pink],
          default: "blue"
        },
        speed: {
          type: "string",
          description: "呼吸の速さ。slow / normal / fast。デフォルトは normal。",
          enum: %w[slow normal fast],
          default: "normal"
        }
      }
    )

    HUE_MAP = {
      "red"    => { hue: 0,     sat: 254 },
      "yellow" => { hue: 12750, sat: 220 },
      "warm"   => { hue: 8000,  sat: 200 },
      "green"  => { hue: 25500, sat: 254 },
      "blue"   => { hue: 46920, sat: 254 },
      "purple" => { hue: 56100, sat: 254 },
      "pink"   => { hue: 62000, sat: 220 }
    }.freeze

    SPEED_MAP = {
      "slow"   => 1.5,
      "normal" => 0.8,
      "fast"   => 0.3
    }.freeze

    class << self
      def call(color: "blue", speed: "normal", server_context:)
        c = HUE_MAP[color] || HUE_MAP["blue"]
        step_interval = SPEED_MAP[speed] || 0.8
        HueCycler.breathe(hue: c[:hue], sat: c[:sat], step_interval: step_interval)
        MCP::Tool::Response.new([{
          type: "text",
          text: "#{color} の呼吸モード始めたよ！（#{speed}）"
        }])
      end
    end
  end
end
