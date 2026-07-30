# frozen_string_literal: true

class AddDeviseToFsps < ActiveRecord::Migration[7.2]
  def change
    change_table :fsps, bulk: true do |t|
      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at
    end

    remove_index :fsps, :email if index_exists?(:fsps, :email)
    add_index :fsps, :email, unique: true
    add_index :fsps, :reset_password_token, unique: true
  end
end
