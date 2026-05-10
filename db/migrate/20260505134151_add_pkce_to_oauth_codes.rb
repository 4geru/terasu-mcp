class AddPkceToOauthCodes < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_codes, :code_challenge, :string
    add_column :oauth_codes, :code_challenge_method, :string
  end
end
