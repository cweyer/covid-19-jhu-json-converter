require_relative 'base'
require_relative '../country_mappings'

class Parser::Global < Parser::Base
  def execute
    # Parse the CSV
    responses = transform

    # Skip the first row, which is headers not data
    responses[1..-1].each do |row|
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
          county: nil,
          country: row[1],
          lat: row[2],
          long: row[3],
          iso_3166: {
            country: iso_country&.dig('name'),
            country_code: iso_country&.dig('code'),
            division_code: iso_country&.dig(row[1], 'divisions', row[0]),
          },
          coordinates: [row[2].to_f, row[3].to_f],
          dates: responses[0][4..-1].map { |d| Date.strptime(d, '%m/%d/%y') },
          data: {}
        }
      end

      # Add the actual numbers to the combined dataset
      results[identifier][:data][@set] = row[4..-1].map(&:to_i)
    end

    return results
  end

private
  def transform
    CSV.parse(data)
  end
end
