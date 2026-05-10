require "net/http"
require "json"

class LineService
  CHANNEL_ID     = ENV["LINE_CHANNEL_ID"]
  CHANNEL_SECRET = ENV["LINE_CHANNEL_SECRET"]
  TOKEN_URL      = "https://api.line.me/oauth2/v2.1/token"
  PROFILE_URL    = "https://api.line.me/v2/profile"

  def self.exchange_token(code:, redirect_uri:)
    uri  = URI(TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(
      grant_type:    "authorization_code",
      code:          code,
      redirect_uri:  redirect_uri,
      client_id:     CHANNEL_ID,
      client_secret: CHANNEL_SECRET
    )

    res = http.request(req)
    JSON.parse(res.body)
  end

  def self.profile(access_token:)
    uri  = URI(PROFILE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Get.new(uri.path)
    req["Authorization"] = "Bearer #{access_token}"

    res = http.request(req)
    JSON.parse(res.body)
  end

  def self.authorize_url(redirect_uri:, state:)
    params = {
      response_type: "code",
      client_id:     CHANNEL_ID,
      redirect_uri:  redirect_uri,
      scope:         "profile",
      state:         state
    }
    "https://access.line.me/oauth2/v2.1/authorize?" + URI.encode_www_form(params)
  end
end
