require 'bundler/inline'
require 'csv'
require 'digest/sha2'
require 'json'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'httparty'
end

# Load most recent data from JHU via Github
responses, results, json = {}, {}, nil

%w( confirmed deaths recovered ).each do |set|
  # Retrieve the data from Github
  data = HTTParty.get("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_#{set}_global.csv").body

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
      results[identifier] = {
        area: row[0],
        country: row[1],
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
puts results.values.to_json
