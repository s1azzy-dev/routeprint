module Flights
  # Loads only an already-authorized flight scope and its display references.
  class HistoryQuery
    def self.call(scope:)
      preload_references(scope).order(departure_date: :desc, id: :desc)
    end

    def self.preload_references(scope)
      scope.includes(departure_place: [ :airport, :place_names ], arrival_place: [ :airport, :place_names ],
        flight_detail: { marketing_airline: [ :designators, country: :country_names ],
          operating_airline: [ :designators, country: :country_names ] })
    end
  end
end
