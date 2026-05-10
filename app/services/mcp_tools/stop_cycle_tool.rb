module McpTools
  module StopCycleTool
    DEFINITION = {
      name: "stop_color_cycle",
      description: "サイクルモード・呼吸モードなど動いているモードをすべて停止する。",
      inputSchema: {
        type: "object",
        properties: {}
      }
    }.freeze

    def self.call(_args)
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
        "#{stopped.join("・")}モードを止めたよ！"
      else
        "動いているモードはないよ"
      end
    end
  end
end
