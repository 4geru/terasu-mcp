class OauthCode < ApplicationRecord
  before_create :set_line_state
  before_create :set_expiry

  scope :valid,   -> { where("expires_at > ?", Time.current) }
  scope :pending, -> { where(code: nil) }

  def confirmed?
    code.present?
  end

  def confirm!(line_user_id:)
    update!(
      code:         SecureRandom.hex(16),
      line_user_id: line_user_id
    )
  end

  private

  def set_line_state
    self.line_state = SecureRandom.hex(16)
  end

  def set_expiry
    self.expires_at = 5.minutes.from_now
  end
end
