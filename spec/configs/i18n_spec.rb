require "rails_helper"

RSpec.describe I18n do
  it "keeps complete matching English and Russian copy contracts" do
    english = flattened_copy(described_class.t("airlines.picker", locale: :en))
    russian = flattened_copy(described_class.t("airlines.picker", locale: :ru))

    expect(russian.keys).to match_array(english.keys)
    expect(english.values + russian.values).to all(be_a(String).and(be_present))
  end

  def flattened_copy(value, prefix = nil)
    value.each_with_object({}) do |(key, child), flattened|
      path = [ prefix, key ].compact.join(".")
      flattened.merge!(child.is_a?(Hash) ? flattened_copy(child, path) : { path => child })
    end
  end
end
