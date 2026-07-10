class CreatePlaceAndAirportFoundation < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE places (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        kind text NOT NULL,
        name text NOT NULL,
        municipality_name text,
        country_code text NOT NULL,
        region_code text,
        continent_code text,
        location geography(Point, 4326) NOT NULL,
        time_zone text,
        time_zone_source text,
        time_zone_verified_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE INDEX index_places_on_location ON places USING gist (location);
    SQL

    execute <<~SQL
      CREATE INDEX index_places_on_country_code ON places (country_code);
    SQL

    execute <<~SQL
      CREATE TABLE place_names (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        place_id uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
        locale text NOT NULL,
        name text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT place_names_place_id_locale_key UNIQUE (place_id, locale)
      );
    SQL

    execute <<~SQL
      CREATE INDEX index_place_names_on_place_id ON place_names (place_id);
    SQL

    execute <<~SQL
      CREATE TABLE airports (
        place_id uuid PRIMARY KEY REFERENCES places(id) ON DELETE CASCADE,
        operational_status text NOT NULL,
        iata_code text,
        icao_code text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE INDEX index_airports_on_iata_code
      ON airports (iata_code)
      WHERE iata_code IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE INDEX index_airports_on_icao_code
      ON airports (icao_code)
      WHERE icao_code IS NOT NULL;
    SQL
  end

  def down
    execute "DROP TABLE IF EXISTS airports;"
    execute "DROP TABLE IF EXISTS place_names;"
    execute "DROP TABLE IF EXISTS places;"
  end
end
