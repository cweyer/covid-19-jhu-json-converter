module Parser
  class Base
    @@iso_countries_by_name = Hash.new
    attr_accessor :data, :set, :results

    def initialize(data, set:, previous_results: Hash.new)
      @data, @set, @results = data, set.to_sym, previous_results
      fetch_iso_countries
    end

    def iso_countries_by_name
      @@iso_countries_by_name || fetch_iso_countries
    end

    def execute
      raise NotImplementedError
    end

    def fetch_iso_countries
      # Load the countries
      iso_countries = JSON.parse(HTTParty.get("https://raw.githubusercontent.com/olahol/iso-3166-2.json/master/iso-3166-2.json").body)

      # Re-map the countries for better access
      iso_countries.each do |key, country|
        new_country = country
        new_country['code'] = key
        new_country['divisions'] = new_country['divisions'].invert

        @@iso_countries_by_name[country['name']] = new_country
      end
    end
  end
end
