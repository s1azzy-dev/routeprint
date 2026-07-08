# frozen_string_literal: true

require "dry/configurable"
require "dry/types"

module Routeprint
  module Configurable
    Dry::Types.load_extensions(:maybe)

    module T
      Types = Dry.Types()
    end

    def self.extended(mod)
      mod.include(T)
      mod.extend(Dry::Configurable)
    end
  end
end
