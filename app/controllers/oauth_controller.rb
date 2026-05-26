class OauthController < ApplicationController
  # GET /.well-known/oauth-protected-resource(/*resource)
  def protected_resource_metadata
    resource_url = params[:resource].present? ? "#{base_url}/#{params[:resource]}" : base_url
    render json: {
      resource: resource_url,
      authorization_servers: [base_url]
    }
  end

  # GET /.well-known/oauth-authorization-server
  def authorization_server_metadata
    render json: {
      issuer: base_url,
      authorization_endpoint: "#{base_url}/oauth/authorize",
      token_endpoint: "#{base_url}/oauth/token",
      registration_endpoint: "#{base_url}/register",
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

  private

  # 実際のリクエストの host/port から組み立てるのでサーバーポート変更に自動追従する。
  # リバースプロキシ越しでも X-Forwarded-* ヘッダ経由で正しい host_with_port が取得される。
  def base_url
    "#{request.protocol}#{request.host_with_port}"
  end
end
