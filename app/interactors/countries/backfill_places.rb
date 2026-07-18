module Countries
  # Links legacy places to countries by their existing normalized country code.
  #
  # @example
  #   Countries::BackfillPlaces.call
  class BackfillPlaces < ApplicationInteractor
    option :places_scope, default: -> { Place.where(country_id: nil) }

    def call
      places = places_scope.to_a
      countries_by_code = Country.where(code: places.filter_map(&:country_code).uniq).index_by(&:code)
      unmatched_codes = []

      ApplicationRecord.transaction do
        places.each do |place|
          country = countries_by_code[place.country_code]
          if country
            place.update!(country:)
          else
            unmatched_codes << place.country_code
          end
        end
      end

      Success(matched_count: places.size - unmatched_codes.size, unmatched_codes: unmatched_codes.uniq.sort)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    end
  end
end
