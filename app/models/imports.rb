module Imports
  def self.table_name_prefix
    "import_"
  end

  module PayloadDigest
    module_function

    def checksum(raw_payload:, normalized_payload:)
      canonical = {
        "raw_payload" => canonicalize(raw_payload),
        "normalized_payload" => canonicalize(normalized_payload)
      }

      Digest::SHA256.hexdigest(JSON.generate(canonical))
    end

    def canonicalize(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, nested_value), result|
          result[key.to_s] = canonicalize(nested_value)
        end.sort.to_h
      when Array
        value.map { |nested_value| canonicalize(nested_value) }
      else
        value
      end
    end
    private_class_method :canonicalize
  end
end
