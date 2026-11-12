module Flights
  # Aggregates an already-authorized flight scope before loading coordinates.
  class RoutePairsQuery
    def self.call(scope:)
      pairs = scope.where(transport_mode: "flight").select(
        "LEAST(departure_place_id, arrival_place_id) AS first_place_id",
        "GREATEST(departure_place_id, arrival_place_id) AS second_place_id",
        "COUNT(*) AS flight_count"
      ).group("first_place_id", "second_place_id")

      rows = TravelSegment.from(pairs, :route_pairs)
        .joins("JOIN places AS first_place ON first_place.id = route_pairs.first_place_id",
          "JOIN places AS second_place ON second_place.id = route_pairs.second_place_id")
        .order("route_pairs.first_place_id", "route_pairs.second_place_id")
        .pluck(Arel.sql(<<~SQL.squish))
          route_pairs.first_place_id, route_pairs.second_place_id,
          ST_X(first_place.location::geometry), ST_Y(first_place.location::geometry),
          ST_X(second_place.location::geometry), ST_Y(second_place.location::geometry),
          route_pairs.flight_count
        SQL

      rows.map do |first_id, second_id, first_lon, first_lat, second_lon, second_lat, count|
        { id: "#{first_id}:#{second_id}", from: [ first_lon, first_lat ], to: [ second_lon, second_lat ], count: }
      end
    end
  end
end
