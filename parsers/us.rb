require_relative 'base'
require_relative '../country_mappings'

class Parser::US < Parser::Base
  def execute
    # Parse the CSV
    responses = transform
    offset = 0

    # Find the column where the data starts by going through all headers and
    # trying to convert them into a date. If it works we have found our first
    # date column, otherwise we increase the offset towards the first data column
    responses[0].each do |header|
      begin
        Date.strptime(header, '%m/%d/%y')
      rescue Date::Error, TypeError
        offset += 1
      end
    end

    # Skip the first row, which is headers not data
    responses[1..-1].each do |row|
      identifier = row[0]

      iso_country = iso_countries_by_id[row[1]]
      # Build a country entry in our result set, if that has not
      # happend before (this is a precaution in case some datasets only
      # contain death or recovery data)
      unless results.has_key?(identifier)
        results[identifier] = {
          iso2: row[1],
          iso3: row[2],
          code3: row[3],
          fips: row[4],
          admin2: row[5],
          province_state: row[6],
          country: row[7],
          iso_3166: {
            country: 'United States',
            country_code: row[1],
            division_code: iso_country&.dig('divisions', row[6]),
          },
          coordinates: [row[8] == '0.0' ? nil : row[8].to_f, row[9] == '0.0' ? nil : row[9].to_f].compact,
          combined_key: row[10],
          population: row[11],
          dates: responses[0][offset..-1].map { |d| Date.strptime(d, '%m/%d/%y') },
          data: {}
        }
      end

      # Add the actual numbers to the combined dataset
      results[identifier][:data][@set] = row[11..-1].map(&:to_i)
    end

    return results
  end

private
  def transform
    CSV.parse(data)
  end
end
