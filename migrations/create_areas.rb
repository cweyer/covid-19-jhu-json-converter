require_relative '../command_line_options'
require_relative '../database'

class CreateAreaTable < ActiveRecord::Migration[6.0]
  def change
    unless table_exists?(:areas)
      create_table :areas do |table|
        table.string :unique_identifier, null: false
        table.string :iso2
        table.string :iso3
        table.integer :code3
        table.decimal :fips
        table.string :admin2
        table.string :province_state
        table.string :country, null: false
        table.string :combined_key
        table.integer :population
        table.decimal :lat
        table.decimal :long
        table.string :iso_3166_country_name
        table.string :iso_3166_division_code
        table.string :iso_3166_country_code
        table.timestamps
      end
    end
  end
end

# Create the table
CreateAreaTable.migrate(:up)
