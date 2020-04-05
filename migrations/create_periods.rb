require_relative '../command_line_options'
require_relative '../database'

class CreatePeriodsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :periods do |table|
      table.string :area_id, null: false, index: true, foreign_key: true
      table.date :date, null: false, index: true
      table.integer :confirmed
      table.integer :recovered
      table.integer :deaths
      table.timestamps
    end

    add_index :periods, [:area_id, :date], unique: true
  end
end

# Create the table
CreatePeriodsTable.migrate(:up)
