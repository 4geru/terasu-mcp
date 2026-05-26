Rails.application.routes.draw do
  # Doorkeeper が /oauth/authorize, /oauth/token などを提供
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications
  end

  # Devise/OmniAuth — /users/auth/line と /users/auth/line/callback を生成
  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: %i[sessions registrations passwords]

  get "up" => "rails/health#show", as: :rails_health_check

  # MCP 仕様の discovery エンドポイント（Doorkeeper 未対応のため自前）
  # RFC 9728 に従い /.well-known/oauth-protected-resource/<resource-path> も受ける
  get  ".well-known/oauth-protected-resource(/*resource)", to: "oauth#protected_resource_metadata"
  get  ".well-known/oauth-authorization-server",            to: "oauth#authorization_server_metadata"

  # Dynamic Client Registration（Doorkeeper 未対応のため自前）
  post "register", to: "oauth#register"

  # MCP endpoint
  match "/mcp", to: "mcp#handle", via: [:get, :post, :delete]
end
