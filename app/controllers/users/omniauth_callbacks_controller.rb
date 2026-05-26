class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    session[:user_id] = user.id
    redirect_to(session.delete(:oauth_return_to) || "/")
  end

  def failure
    redirect_to "/", alert: "LINE 認証に失敗しました (#{failure_message})"
  end
end
