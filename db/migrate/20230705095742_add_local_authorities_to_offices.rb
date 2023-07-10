# frozen_string_literal: true

class AddLocalAuthoritiesToOffices < ActiveRecord::Migration[7.0]
  def change
    add_reference :offices, :local_authority, foreign_key: true, type: "char(9)"
  end
end
