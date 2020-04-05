require 'csv'
require 'digest/sha2'
require 'json'
require 'httparty'
require './country_mappings'
require './command_line_options'
require './parsers/global'

VERSION = 0.2
responses, results, iso_countries_by_name, json = {}, {}, {}, nil

# Load most recent data from JHU via Github
%w( confirmed deaths recovered ).each do |set|
  # Retrieve the data from Github
  url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_#{set}_#{OPTIONS[:region]}.csv"
  puts "Loading: #{url}"

  data = HTTParty.get(url).body

  parser = Parser::Global.new(data, set: set, previous_results: results)
  responses[set] = parser.execute
end

# Return everything as json
case OPTIONS[:output]
when 'file'
  File.write(OPTIONS[:filename] || "#{DateTime.now.strftime("%d-%m-%Y")}.json", results.values.to_json)

when 'database'
  require './database'
  require './area'
  require './period'

  results.each do |key, area|
    puts "Importing data for #{area[:country]}/#{area[:area]}"

    db_area = Area.find_or_create_by(
      unique_identifier: key,
      name: area[:area],
      country: area[:country]
    )

    db_area.update(
      iso_3166_country_name: area[:iso_3166][:country],
      iso_3166_country_code: area[:iso_3166][:country_code],
      iso_3166_division_code: area[:iso_3166][:division_code]
    )

    days = 0
    area[:dates].each_with_index do |day, index|
      period = db_area.periods.find_or_create_by(
        date: day
      )

      period.update(
        confirmed: area[:data][:confirmed]&.at(index),
        recovered: area[:data][:recovered]&.at(index),
        deaths: area[:data][:deaths]&.at(index)
      )

      days += 1
    end

    puts "Imported #{days} data sets for #{area[:country]}/#{area[:area]}"
  end
else
  puts results.values.to_json
end
