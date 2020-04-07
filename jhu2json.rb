require 'csv'
require 'digest/sha2'
require 'json'
require 'httparty'
require './country_mappings'
require './command_line_options'
require './parsers/global'
require './parsers/us'

VERSION = 0.2
responses, results, iso_countries_by_name, json = {}, {}, {}, nil

%w( global US ).each do |region|
  # Load most recent data from JHU (Glboal) via Github
  %w( confirmed deaths recovered ).each do |set|
    # Retrieve the data from Github
    url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_#{set}_#{region}.csv"
    puts "Loading #{region} data for #{url}"

    response = HTTParty.get(url)

    # Skip if we can't download the file
    unless response.code == 200
      puts "Retrieved code #{response.code} when attempting to download file, skipping"
      next
    end

    data = response.body

    parser = case region
    when 'global' then Parser::Global.new(data, set: set, previous_results: results)
    when 'US'     then Parser::US.new(data, set: set, previous_results: results)
    end

    responses.has_key?(set) ? responses[set].merge(parser.execute) : responses[set] = parser.execute
  end
end

# Return everything as json
case OPTIONS[:output]
when 'file'
  File.write(OPTIONS[:filename] || "#{DateTime.now.strftime("%d-%m-%Y")}.json", results.values.to_json)

when 'database'
  require './database'
  require './area'
  require './period'
  require './migrations/create_areas'
  require './migrations/create_periods'

  results.each do |key, area|
    puts "Importing data for #{area[:country]}/#{area[:province_state]}/#{area[:admin2]}"

    db_area = Area.find_or_create_by(
      unique_identifier: key,
      iso2: area[:iso2],
      iso3: area[:iso3],
      code3: area[:code3],
      fips: area[:fips],
      admin2: area[:admin2],
      province_state: area[:province_state],
      country: area[:country],
      combined_key: area[:combined_key],
      population: area[:population],
      lat: area[:coordinates].first,
      long: area[:coordinates].last
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

    puts "Imported #{days} data sets for #{area[:country]}/#{area[:area]}/#{area[:county]}"
  end
else
  puts results.values.to_json
end
