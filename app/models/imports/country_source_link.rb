module Imports
  class CountrySourceLink < ApplicationRecord
    belongs_to :source_record, class_name: "Imports::SourceRecord", inverse_of: :country_source_link
    belongs_to :country

    validates :matched_at, presence: true
  end
end
