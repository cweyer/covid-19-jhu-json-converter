require 'csv'
require 'digest/sha2'
require 'json'
require 'httparty'
require 'slop'
require './country_mappings'

VERSION = 0.1

opts = Slop.parse do |o|
  o.bool '-h', '--help', 'help'
  # TODO: Make this an array and default to everything.
  o.string '-r', '--region', "input file region (default: global)", default: "global"
  o.string '-o', '--output', "output to file, database or STDOUT (default: STDOUT)"
  o.string '-f', '--filename', "use this file name when outputting to file (defaults to current date)"
  o.string '-c', '--credentials', "set database credentials as URI (example: postgres://user:password@localhost:1337/mydb)"
  o.on '--version', 'print the version' do
    puts VERSION
    exit
  end
end

if opts.help?
  puts opts
  exit
end

responses, results, iso_countries_by_name, json = {}, {}, {}, nil

# Load country mapping and re-hash for country name access
iso_countries = JSON.parse(HTTParty.get("https://raw.githubusercontent.com/olahol/iso-3166-2.json/master/iso-3166-2.json").body)
iso_countries.each do |key, country|
  new_country = country
  new_country['code'] = key
  new_country['divisions'] = new_country['divisions'].invert

  iso_countries_by_name[country['name']] = new_country
end

# Load most recent data from JHU via Github
%w( confirmed deaths recovered ).each do |set|
  # Retrieve the data from Github
  url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_#{set}_#{opts[:region]}.csv"
  puts "Loading: #{url}"

  data = HTTParty.get(url).body

  # Parse the CSV
  responses[set] = CSV.parse(data)

  # Skip the first row, which is headers not data
  responses[set][1..-1].each do |row|
    # Build an identifier digest to ensure we talk about the same rows across
    # all three datasets, this contains:
    # - area name
    # - country name
    # - latitude
    # - longitude
    identifier = Digest::SHA512.hexdigest("#{row[0]}|#{row[1]}|#{row[2]}|#{row[3]}")

    # Build a country entry in our result set, if that has not
    # happend before (this is a precaution in case some datasets only
    # contain death or recovery data)
    unless results.has_key?(identifier)
      iso_country = iso_countries_by_name[row[1]] || iso_countries_by_name[MANUAL_COUNTRY_MAPPINGS[row[1]]]

      results[identifier] = {
        area: row[0],
        country: row[1],
        iso_3166: {
          country: iso_country&.dig('name'),
          country_code: iso_country&.dig('code'),
          division_code: iso_country&.dig(row[1], 'divisions', row[0]),
        },
        coordinates: [row[2], row[3]],
        dates: responses[set][0][4..-1].map { |d| Date.strptime(d, '%m/%d/%y') },
        data: {}
      }
    end

    # Add the actual numbers to the combined dataset
    results[identifier][:data][set.to_sym] = row[4..-1].map(&:to_i)
  end
end

# Return everything as json
case opts[:output]
when 'file'
  File.write(opts[:filename] || "#{DateTime.now.strftime("%d-%m-%Y")}.json", results.values.to_json)

when 'database'
  require 'sqlite3'
  require 'active_record'
  require './area'
  require './period'

  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'covid.db')

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
