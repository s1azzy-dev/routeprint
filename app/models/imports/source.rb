module Imports
  class Source < ApplicationRecord
    FETCH_MODES = %w[remote_dump api scrape].freeze

    has_many :runs, class_name: "Imports::Run", foreign_key: :source_id, inverse_of: :source, dependent: :restrict_with_exception
    has_many :source_records, class_name: "Imports::SourceRecord", foreign_key: :source_id, inverse_of: :source, dependent: :restrict_with_exception

    normalizes :key, with: ->(value) { value.to_s.strip.presence }
    normalizes :provider_key, :dataset_key, :target_kind, with: ->(value) { value.to_s.strip.downcase.presence }

    validates :key, presence: true, uniqueness: true
    validates :provider_key, :dataset_key, :target_kind, presence: true
    validates :fetch_mode, presence: true, inclusion: { in: FETCH_MODES }
    validates :license_key, presence: true
  end
end
