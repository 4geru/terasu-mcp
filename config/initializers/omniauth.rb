# Doorkeeper からの GET リダイレクトで OmniAuth を起動するため GET を許可する。
# CSRF は OAuth の state パラメータで担保される。
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
