class User < ApplicationRecord
  devise :trackable

  def self.find_or_create_from_line(line_user_id:)
    find_or_create_by!(line_user_id: line_user_id)
  end
end
