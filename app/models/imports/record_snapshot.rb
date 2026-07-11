module Imports
  class RecordSnapshot < ApplicationRecord
    belongs_to :source_record, class_name: "Imports::SourceRecord", inverse_of: :snapshots
    belongs_to :run, class_name: "Imports::Run", inverse_of: :snapshots

    validates :checksum, :captured_at, presence: true
  end
end
