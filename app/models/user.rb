class User < ApplicationRecord
  devise :trackable, :omniauthable, omniauth_providers: %i[line]

  def self.from_omniauth(auth)
    find_or_create_by!(line_user_id: auth.uid)
  end
end
