module Airports
  # Prefix lookup uses expression indexes for names and public code indexes.
  class PickerSearch
    def self.call(query:, locale:)
      pattern = "#{Place.sanitize_sql_like(query.downcase)}%"
      names = PlaceName.where(locale:).where("lower(name) LIKE ?", pattern).select(:place_id)
      code = query.upcase
      airports = Airport.where(iata_code: code).or(Airport.where(icao_code: code)).select(:place_id)
      base = Place.joins(:airport)
      base.where("lower(places.name) LIKE ?", pattern)
        .or(base.where(id: names)).or(base.where(id: airports))
        .includes(:airport, :place_names).order(:name, :id).limit(20)
    end
  end
end
