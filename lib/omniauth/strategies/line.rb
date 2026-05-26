require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Line < OmniAuth::Strategies::OAuth2
      option :name, "line"

      option :client_options, {
        site:          "https://api.line.me",
        authorize_url: "https://access.line.me/oauth2/v2.1/authorize",
        token_url:     "https://api.line.me/oauth2/v2.1/token"
      }

      option :authorize_options, %i[scope state]

      uid { raw_info["userId"] }

      info do
        {
          name:  raw_info["displayName"],
          image: raw_info["pictureUrl"]
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get("/v2/profile").parsed
      end

      def callback_url
        full_host + callback_path
      end
    end
  end
end
