class SessionsController < ActionController::Base
  BASE_URL = ENV.fetch("BASE_URL", "http://localhost:3000")
  LINE_CALLBACK_URL = "#{BASE_URL}/oauth/line/callback"

  # GET /sessions/line_authorize
  def line_authorize
    state = SecureRandom.hex(16)
    session[:line_state] = state
    redirect_to LineService.authorize_url(redirect_uri: LINE_CALLBACK_URL, state: state),
                allow_other_host: true
  end

  # GET /sessions/line_callback
  def line_callback
    unless ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, session[:line_state].to_s)
      render plain: "Invalid state.", status: :bad_request and return
    end

    token_res = LineService.exchange_token(code: params.require(:code), redirect_uri: LINE_CALLBACK_URL)
    unless token_res["access_token"]
      render plain: "LINE token exchange failed.", status: :bad_request and return
    end

    profile = LineService.profile(access_token: token_res["access_token"])
    user = User.find_or_create_from_line(line_user_id: profile["userId"])

    session[:user_id] = user.id
    return_to = session.delete(:oauth_return_to) || "/"
    redirect_to return_to
  end
end
