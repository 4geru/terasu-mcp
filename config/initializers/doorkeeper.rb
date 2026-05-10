# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  # セッションから current_user を取得。未ログインなら LINE Login へ
  resource_owner_authenticator do
    if session[:user_id]
      User.find_by(id: session[:user_id])
    else
      session[:oauth_return_to] = request.fullpath
      redirect_to "/sessions/line_authorize"
    end
  end

  # 認可確認画面をスキップ（Claude は trusted client）
  skip_authorization { true }

  # PKCE を必須にする
  force_pkce

  grant_flows %w[authorization_code]
  access_token_expires_in 1.hour

  default_scopes :mcp
end
