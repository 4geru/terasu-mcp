class CreateOauthTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_tokens do |t|
      t.string :token
      t.string :client_id
      t.datetime :expires_at

      t.timestamps
    end
  end
end
