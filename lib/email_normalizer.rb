module EmailNormalizer
  module_function

  def normalize(value)
    value.to_s.strip.downcase.presence
  end
end
