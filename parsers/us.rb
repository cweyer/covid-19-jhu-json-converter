require_relative 'base'
require_relative '../country_mappings'

class Parser::US < Parser::Base
  def execute
    # Parse the CSV
    responses = transform

    # Skip the first row, which is headers not data
    responses[1..-1].each do |row|
      identifier = row[0]

      # Build a country entry in our result set, if that has not
      # happend before (this is a precaution in case some datasets only
      # contain death or recovery data)
      unless results.has_key?(identifier)
        results[identifier] = {
          area: row[6],
          county: row[5],
          country: row[1],
          iso_3166: {
            country: 'United States',
            country_code: row[2],
            division_code: row[5],
          },
          coordinates: [row[8] == '0.0' ? nil : row[8].to_f, row[9] == '0.0' ? nil : row[9].to_f].compact,
          dates: responses[0][11..-1].map { |d| Date.strptime(d, '%m/%d/%y') },
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