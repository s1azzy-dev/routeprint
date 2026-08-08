module Airlines
  # Finds bounded selectable airline candidates for an authenticated picker.
  #
  # @example
  #   Airlines::Search.call(input: { query: "BA", flight_date: Date.new(2026, 8, 8) })
  # @param input [Hash] search query and optional historical flight date
  class Search < ApplicationInteractor
    RESULT_LIMIT = 20

    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:query).filled(:string, max_size?: 100)
        optional(:flight_date).maybe(:date)
      end
    end

    def call
      query = input.fetch(:query).squish
      return fail_with(code: :validation_error, errors: { query: [ "must be filled" ] }) if query.blank?

      flight_date = parse_flight_date(input[:flight_date])
      airlines = ordered_scope(query:, flight_date:)
        .includes(:designators, country: :country_names)
        .limit(RESULT_LIMIT)
        .to_a

      Success(airlines:, flight_date:)
    end

    private

    def parse_flight_date(value)
      return if value.blank?

      Date.iso8601(value.to_s)
    end

    def ordered_scope(query:, flight_date:)
      normalized_query = query.downcase
      system = designator_system(query)
      scope = matching_scope(normalized_query:, query:, system:)

      scope
        .order(review_order)
        .order(exact_name_order(normalized_query))
        .then { |ordered| order_by_designator_date(ordered, system:, code: query.upcase, flight_date:) }
        .order(operation_order)
        .order(Arel.sql("airlines.normalized_name ASC, airlines.id ASC"))
    end

    def matching_scope(normalized_query:, query:, system:)
      selectable = Airline.where(review_status: %w[approved pending], record_kind: "catalog")
      name_matches = selectable.where(
        "airlines.normalized_name LIKE ?",
        "#{Airline.sanitize_sql_like(normalized_query)}%"
      )
      return name_matches unless system

      designator_airline_ids = AirlineDesignator.where(system:, code: query.upcase).select(:airline_id)
      name_matches.or(selectable.where(id: designator_airline_ids))
    end

    def designator_system(query)
      return "iata" if query.match?(/\A[A-Z0-9]{2}\z/i)

      "icao" if query.match?(/\A[A-Z]{3}\z/i)
    end

    def review_order
      Arel.sql("CASE airlines.review_status WHEN 'approved' THEN 0 ELSE 1 END")
    end

    def exact_name_order(normalized_query)
      sql = Airline.sanitize_sql_array(
        [ "CASE WHEN airlines.normalized_name = ? THEN 0 ELSE 1 END", normalized_query ]
      )
      Arel.sql(sql)
    end

    def order_by_designator_date(scope, system:, code:, flight_date:)
      return scope unless system && flight_date

      sql = Airline.sanitize_sql_array(
        [
          <<~SQL.squish,
            CASE
              WHEN EXISTS (
                SELECT 1 FROM airline_designators date_designators
                WHERE date_designators.airline_id = airlines.id
                  AND date_designators.system = ?
                  AND date_designators.code = ?
                  AND (date_designators.valid_from IS NOT NULL OR date_designators.valid_until IS NOT NULL)
                  AND (date_designators.valid_from IS NULL OR date_designators.valid_from <= ?)
                  AND (date_designators.valid_until IS NULL OR date_designators.valid_until >= ?)
              ) THEN 0
              WHEN EXISTS (
                SELECT 1 FROM airline_designators dated_designators
                WHERE dated_designators.airline_id = airlines.id
                  AND dated_designators.system = ?
                  AND dated_designators.code = ?
                  AND (dated_designators.valid_from IS NOT NULL OR dated_designators.valid_until IS NOT NULL)
              ) THEN 2
              ELSE 1
            END
          SQL
          system,
          code,
          flight_date,
          flight_date,
          system,
          code
        ]
      )

      scope.order(Arel.sql(sql))
    end

    def operation_order
      Arel.sql(
        "CASE airlines.operational_status WHEN 'active' THEN 0 WHEN 'unknown' THEN 1 ELSE 2 END"
      )
    end
  end
end
