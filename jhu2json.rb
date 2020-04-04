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
  o.string '-o', '--output', "output file (default: STDOUT)"
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
if !opts[:output].nil? && !opts[:output].empty?
  File.write("#{opts[:output]}", results.values.to_json)
else
  puts results.values.to_json
end
