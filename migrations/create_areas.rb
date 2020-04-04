require 'sqlite3'
require 'active_record'

# TODO: Make db configurable
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'covid.db')

class CreateAreaTable < ActiveRecord::Migration[6.0]
  def change
    create_table :areas do |table|
      table.string :unique_identifier, null: false
      table.string :country, null: false
      table.string :name
      table.string :iso_3166_country_name
      table.string :iso_3166_division_code
      table.string :iso_3166_country_code
      table.timestamps
    end
  end
end

# Create the table
CreateAreaTable.migrate(:up)
