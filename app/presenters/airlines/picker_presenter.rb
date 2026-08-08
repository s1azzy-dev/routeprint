module Airlines
  class PickerPresenter
    def initialize(airline:, flight_date:, locale:)
      @airline = airline
      @flight_date = flight_date
      @locale = locale
    end

    def as_json(*)
      {
        id: airline.id,
        name: airline.name,
        preferredCode: preferred_designator&.code,
        countryName: airline.country&.name_for(locale),
        inactive: airline.operational_status == "inactive",
        pending: airline.review_status == "pending"
      }
    end

    private

    attr_reader :airline, :flight_date, :locale

    def preferred_designator
      applicable = airline.designators.select { |designator| applicable_on?(designator, reference_date) }
      preferred_from(applicable) || preferred_from(airline.designators)
    end

    def reference_date
      flight_date || Date.current
    end

    def applicable_on?(designator, date)
      (designator.valid_from.nil? || designator.valid_from <= date) &&
        (designator.valid_until.nil? || designator.valid_until >= date)
    end

    def preferred_from(designators)
      designators.min_by do |designator|
        [ designator.system == "iata" ? 0 : 1, designator.code ]
      end
    end
  end
end
