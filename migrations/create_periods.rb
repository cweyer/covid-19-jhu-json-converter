require 'sqlite3'
require 'active_record'

# TODO: Make db configurable
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'covid.db')

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
