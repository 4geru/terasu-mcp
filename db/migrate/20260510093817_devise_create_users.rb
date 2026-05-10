# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :line_user_id, null: false

      t.timestamps null: false
    end

    add_index :users, :line_user_id, unique: true
  end
end
