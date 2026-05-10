class AddLineStateToOauthCodes < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_codes, :mcp_state, :string
    add_column :oauth_codes, :line_state, :string
    add_column :oauth_codes, :line_user_id, :string
  end
end
