class McpController < ApplicationController
  before_action :authenticate!

  TOOLS = [
    McpTools::IlluminateTool,
    McpTools::TurnOffTool,
    McpTools::SetColorTool,
    McpTools::SetColorCodeTool,
    McpTools::StartCycleTool,
    McpTools::StartBreathingTool,
    McpTools::StopCycleTool
  ].freeze

  TOOL_MAP = TOOLS.index_by { |t| t::DEFINITION[:name] }.freeze

  # GET /mcp
  # MCP discovery (Streamable HTTP)
  def index
    render json: {
      protocolVersion: "2024-11-05",
      serverInfo: { name: "terasu", version: "0.1.0" },
      capabilities: { tools: {} }
    }
  end

  # POST /mcp
  def handle
    rpc = JSON.parse(request.body.read)

    result = case rpc["method"]
    when "initialize"
      handle_initialize(rpc)
    when "tools/list"
      handle_tools_list
    when "tools/call"
      handle_tools_call(rpc["params"])
    else
      return render json: json_rpc_error(rpc["id"], -32601, "Method not found")
    end

    render json: json_rpc_response(rpc["id"], result)
  end

  # GET /mcp/sse
  def sse
    response.headers["Content-Type"]  = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    sse_write("endpoint", { uri: mcp_url })
    response.stream.close
  rescue ActionController::Live::ClientDisconnected
    # client disconnected
  ensure
    response.stream.close rescue nil
  end

  private

  def authenticate!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    return if token && OauthToken.valid.exists?(token: token)
    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def handle_initialize(rpc)
    {
      protocolVersion: rpc.dig("params", "protocolVersion") || "2024-11-05",
      serverInfo: { name: "terasu", version: "0.1.0" },
      capabilities: { tools: {} }
    }
  end

  def handle_tools_list
    { tools: TOOLS.map { |t| t::DEFINITION } }
  end

  def handle_tools_call(params)
    name = params["name"]
    args = params["arguments"] || {}
    tool = TOOL_MAP[name]

    unless tool
      return { isError: true, content: [{ type: "text", text: "Unknown tool: #{name}" }] }
    end

    text = tool.call(args)
    { content: [{ type: "text", text: text }] }
  rescue => e
    { isError: true, content: [{ type: "text", text: e.message }] }
  end

  def json_rpc_response(id, result)
    { jsonrpc: "2.0", id: id, result: result }
  end

  def json_rpc_error(id, code, message)
    { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
  end

  def sse_write(event, data)
    response.stream.write("event: #{event}\ndata: #{data.to_json}\n\n")
  end
end
