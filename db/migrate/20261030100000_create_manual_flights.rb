class CreateManualFlights < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE travel_segments (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        user_id uuid NOT NULL REFERENCES users(id),
        transport_mode text NOT NULL DEFAULT 'flight',
        departure_place_id uuid NOT NULL REFERENCES places(id),
        arrival_place_id uuid NOT NULL REFERENCES places(id),
        departure_date date NOT NULL,
        arrival_date date,
        departure_local_at timestamp without time zone,
        arrival_local_at timestamp without time zone,
        departure_time_zone text,
        arrival_time_zone text,
        departure_at timestamptz,
        arrival_at timestamptz,
        departure_offset_seconds integer,
        arrival_offset_seconds integer,
        departure_resolution text NOT NULL,
        arrival_resolution text NOT NULL,
        creation_request_key uuid NOT NULL,
        creation_digest text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE UNIQUE INDEX index_travel_segments_on_user_and_request
        ON travel_segments(user_id, creation_request_key);
      CREATE INDEX index_travel_segments_on_user_and_departure
        ON travel_segments(user_id, departure_date DESC, id DESC);
      CREATE INDEX index_travel_segments_on_departure_place_id ON travel_segments(departure_place_id);
      CREATE INDEX index_travel_segments_on_arrival_place_id ON travel_segments(arrival_place_id);
      CREATE TABLE flight_details (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        travel_segment_id uuid NOT NULL UNIQUE REFERENCES travel_segments(id),
        marketing_airline_id uuid NOT NULL REFERENCES airlines(id),
        operating_airline_id uuid REFERENCES airlines(id),
        flight_number text,
        marketing_designator text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX index_flight_details_on_marketing_airline_id ON flight_details(marketing_airline_id);
      CREATE INDEX index_flight_details_on_operating_airline_id ON flight_details(operating_airline_id);
    SQL
  end

  def down
    execute "DROP TABLE flight_details;"
    execute "DROP TABLE travel_segments;"
  end
end
