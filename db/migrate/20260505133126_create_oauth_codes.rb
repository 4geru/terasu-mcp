class CreateOauthCodes < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_codes do |t|
      t.string :code
      t.string :client_id
      t.string :redirect_uri
      t.datetime :expires_at

      t.timestamps
    end
  end
end
