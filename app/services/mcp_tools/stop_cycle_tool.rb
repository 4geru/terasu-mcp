module McpTools
  class StopCycleTool < MCP::Tool
    tool_name "stop_color_cycle"
    description "サイクルモード・呼吸モードなど動いているモードをすべて停止する。"
    input_schema(properties: {})

    class << self
      def call(server_context:, **_args)
        stopped = []
        if HueCycler.running?
          HueCycler.stop
          stopped << "サイクル"
        end
        if HueCycler.breathing?
          HueCycler.stop_breathing
          stopped << "呼吸"
        end

        if stopped.any?
          MCP::Tool::Response.new([{ type: "text", text: "#{stopped.join("・")}モードを止めたよ！" }])
        else
          MCP::Tool::Response.new([{ type: "text", text: "動いているモードはないよ" }])
        end
      end
    end
  end
end
