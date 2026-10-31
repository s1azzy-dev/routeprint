module Flights
  # Resolves the bounded reference data needed to redisplay one flight form.
  class FormOptionsQuery
    def self.call(values:)
      places = Place.includes(:airport, :place_names)
        .where(id: values.values_at(:departure_place_id, :arrival_place_id)).index_by(&:id)
      airlines = Airline.includes(:designators, country: :country_names)
        .where(id: values.values_at(:marketing_airline_id, :operating_airline_id)).index_by(&:id)
      {
        places:,
        airlines:,
        countries: Country.includes(:country_names).order(:name).limit(500)
      }
    end
  end
end
