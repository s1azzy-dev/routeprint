module Airports
  class PickerPresenter
    def self.call(place, locale:)
      return unless place&.airport

      airport = place.airport
      { id: place.id, name: place.place_names.find { |name| name.locale == locale.to_s }&.name || place.name,
        iataCode: airport.iata_code, icaoCode: airport.icao_code, countryCode: place.country_code,
        closed: airport.operational_status == "closed" }
    end
  end
end
