class McpController < ApplicationController
  before_action :doorkeeper_authorize!

  TOOLS = [
    McpTools::IlluminateTool,
    McpTools::TurnOffTool,
    McpTools::SetColorTool,
    McpTools::SetColorCodeTool,
    McpTools::StartCycleTool,
    McpTools::StartBreathingTool,
    McpTools::StopCycleTool
  ].freeze

  def handle
    server = MCP::Server.new(
      name: "terasu",
      version: "0.1.0",
      tools: TOOLS
    )
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
    status, headers, body = transport.handle_request(request)

    response.headers.merge!(headers)
    body_content = body.first
    Rails.logger.info "[MCP Response] status=#{status} body_class=#{body_content.class} body=#{body_content.inspect}"
    render body: body_content, content_type: "application/json", status: status
  end

end
