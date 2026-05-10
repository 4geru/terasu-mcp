Rails.application.routes.draw do
  # Doorkeeper が /oauth/authorize, /oauth/token などを提供
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # MCP 仕様の discovery エンドポイント（Doorkeeper 未対応のため自前）
  get  ".well-known/oauth-protected-resource",  to: "oauth#protected_resource_metadata"
  get  ".well-known/oauth-authorization-server", to: "oauth#authorization_server_metadata"

  # Dynamic Client Registration（Doorkeeper 未対応のため自前）
  post "register", to: "oauth#register"

  # LINE Login フロー用セッション
  scope :sessions do
    get "line_authorize", to: "sessions#line_authorize"
  end
  # LINE Developers に登録済みの callback URL を維持
  get "oauth/line/callback", to: "sessions#line_callback"

  # MCP endpoint
  match "/mcp", to: "mcp#handle", via: [:get, :post, :delete]
end
