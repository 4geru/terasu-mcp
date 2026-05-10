Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # OAuth discovery
  get  ".well-known/oauth-protected-resource",  to: "oauth#protected_resource_metadata"
  get  ".well-known/oauth-authorization-server", to: "oauth#authorization_server_metadata"
  post "register", to: "oauth#register"

  # OAuth 2.0 endpoints
  scope :oauth do
    get  "authorize",      to: "oauth#authorize"
    post "token",          to: "oauth#token"
    get  "line/callback",  to: "oauth#line_callback"
  end

  # MCP endpoint (GET / POST / DELETE を handle で受ける)
  match "/mcp", to: "mcp#handle", via: [:get, :post, :delete]
end
