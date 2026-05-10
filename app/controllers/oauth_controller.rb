class OauthController < ApplicationController
  BASE_URL         = ENV.fetch("BASE_URL", "http://localhost:3000")
  LINE_CALLBACK_URL = "#{BASE_URL}/oauth/line/callback"

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

  # POST /register
  def register
    client_id = SecureRandom.hex(16)
    render json: {
      client_id: client_id,
      client_id_issued_at: Time.current.to_i,
      redirect_uris: params[:redirect_uris],
      grant_types: ["authorization_code"],
      response_types: ["code"]
    }, status: :created
  end

  # GET /oauth/authorize
  def authorize
    oauth_code = OauthCode.create!(
      client_id:            params.require(:client_id),
      redirect_uri:         params.require(:redirect_uri),
      mcp_state:            params[:state],
      code_challenge:       params[:code_challenge],
      code_challenge_method: params[:code_challenge_method]
    )

    redirect_to LineService.authorize_url(
      redirect_uri: LINE_CALLBACK_URL,
      state:        oauth_code.line_state
    ), allow_other_host: true
  end

  # GET /oauth/line/callback
  def line_callback
    line_state = params.require(:state)
    line_code  = params.require(:code)

    oauth_code = OauthCode.valid.pending.find_by(line_state: line_state)
    unless oauth_code
      return render plain: "Invalid or expired state.", status: :bad_request
    end

    token_res = LineService.exchange_token(code: line_code, redirect_uri: LINE_CALLBACK_URL)
    unless token_res["access_token"]
      return render plain: "LINE token exchange failed.", status: :bad_request
    end

    profile = LineService.profile(access_token: token_res["access_token"])
    oauth_code.confirm!(line_user_id: profile["userId"])

    redirect_to "#{oauth_code.redirect_uri}?code=#{oauth_code.code}&state=#{oauth_code.mcp_state}",
                allow_other_host: true
  end

  # POST /oauth/token
  def token
    code      = params.require(:code)
    client_id = params.require(:client_id)

    oauth_code = OauthCode.valid.find_by(code: code, client_id: client_id)
    unless oauth_code
      return render json: { error: "invalid_grant" }, status: :bad_request
    end

    if oauth_code.code_challenge.present?
      unless valid_pkce?(oauth_code, params[:code_verifier])
        return render json: { error: "invalid_grant" }, status: :bad_request
      end
    end

    oauth_code.destroy
    oauth_token = OauthToken.create!(client_id: client_id)

    render json: {
      access_token: oauth_token.token,
      token_type:   "Bearer",
      expires_in:   3600
    }
  end

  private

  def valid_pkce?(oauth_code, code_verifier)
    return false if code_verifier.blank?
    digest = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
    ActiveSupport::SecurityUtils.secure_compare(digest, oauth_code.code_challenge)
  end
end
