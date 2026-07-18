module Imports
  class CountryNameSourceLink < ApplicationRecord
    belongs_to :source_record, class_name: "Imports::SourceRecord", inverse_of: :country_name_source_link
    belongs_to :country_name

    validates :matched_at, presence: true
  end
end
