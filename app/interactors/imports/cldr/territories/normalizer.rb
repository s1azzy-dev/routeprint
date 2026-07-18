# frozen_string_literal: true

module Imports
  module Cldr
    module Territories
      # Normalizes one CLDR territory-name record.
      class Normalizer
        def self.call(row)
          new(row).call
        end

        def initialize(row)
          @row = row.transform_keys(&:to_s)
        end

        def call
          external_uid = value("id")
          code = value("code")&.upcase
          locale = value("locale")&.downcase
          name = value("name")
          return failure(:missing_external_uid, :id) unless external_uid
          return failure(:invalid_country_code, :code) unless code&.match?(/\A[A-Z]{2}\z/)
          return failure(:unsupported_locale, :locale) unless I18n.available_locales.map(&:to_s).include?(locale)
          return failure(:missing_name, :name) unless name

          Dry::Monads::Success(
            external_uid:,
            record_kind: "country_name",
            normalized_payload: { "code" => code, "locale" => locale, "name" => name }
          )
        end

        private

        def value(key)
          @row[key].to_s.strip.presence
        end

        def failure(code, field)
          Dry::Monads::Failure(code:, errors: { field => [ "is required or invalid" ] })
        end
      end
    end
  end
end
