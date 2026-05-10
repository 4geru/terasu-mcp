class OauthToken < ApplicationRecord
  before_create :generate_token

  scope :valid, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token
    self.token = SecureRandom.hex(32)
    self.expires_at = 1.hour.from_now
  end
end
