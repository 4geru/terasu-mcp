class OauthController < ApplicationController
  BASE_URL = ENV.fetch("BASE_URL", "http://localhost:3000")

  # GET /.well-known/oauth-protected-resource
  def protected_resource_metadata
    render json: {
      resource: BASE_URL,
      authorization_servers: [BASE_URL]
    }
  end

  # GET /.well-known/oauth-authorization-server
  def authorization_server_metadata
    render json: {
      issuer: BASE_URL,
      authorization_endpoint: "#{BASE_URL}/oauth/authorize",
      token_endpoint: "#{BASE_URL}/oauth/token",
      registration_endpoint: "#{BASE_URL}/register",
      response_types_supported: ["code"],
      grant_types_supported: ["authorization_code"],
      code_challenge_methods_supported: ["S256"]
    }
  end

  # POST /register  (Dynamic Client Registration)
  def register
    app = Doorkeeper::Application.create!(
      name:         params[:client_name].presence || "MCP Client #{SecureRandom.hex(4)}",
      redirect_uri: Array(params[:redirect_uris]).join("\n"),
      scopes:       "",
      confidential: false
    )

    render json: {
      client_id:           app.uid,
      client_id_issued_at: Time.current.to_i,
      redirect_uris:       params[:redirect_uris],
      grant_types:         ["authorization_code"],
      response_types:      ["code"]
    }, status: :created
  end
end
