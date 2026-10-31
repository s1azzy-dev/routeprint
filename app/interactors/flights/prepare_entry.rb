module Flights
  # Validates a complete manual entry and constructs its schedule and carrier evidence.
  #
  # @example
  #   Flights::PrepareEntry.call(input: { attributes:, flight: nil })
  # @param input [Hash] editable attributes and optional existing flight
  class PrepareEntry < ApplicationInteractor
    option :input
    option :unknown_resolver, default: -> { Airlines::BootstrapUnknown }

    class ValidationContract < ApplicationContract
      params do
        required(:attributes).hash do
          required(:departure_place_id).filled(:string)
          required(:arrival_place_id).filled(:string)
          required(:departure_date).filled(:string)
          optional(:arrival_date).maybe(:string)
          optional(:departure_time).maybe(:string)
          optional(:arrival_time).maybe(:string)
          optional(:marketing_airline_id).maybe(:string)
          optional(:operating_airline_id).maybe(:string)
          optional(:flight_number).maybe(:string)
        end
        optional(:flight).maybe(type?: TravelSegment)
      end
    end

    def call
      values = EntryAttributes.normalize(input.fetch(:attributes))
      flight = input[:flight]
      departure = yield airport(values[:departure_place_id], :departure_place_id)
      arrival = yield airport(values[:arrival_place_id], :arrival_place_id)
      departure_date = yield calendar_date(values[:departure_date], :departure_date)
      arrival_date = yield calendar_date(values[:arrival_date], :arrival_date, optional: true)
      yield validate_schedule(values, departure:, departure_date:, arrival_date:)
      marketing = yield carrier(values[:marketing_airline_id], :marketing_airline_id)
      operating = yield carrier(values[:operating_airline_id], :operating_airline_id, optional: true)
      schedule = yield schedule_attributes(values, flight:, departure:, arrival:, departure_date:, arrival_date:)

      Success(segment: schedule.merge(departure_place: departure, arrival_place: arrival,
        departure_date:, arrival_date:), detail: detail_attributes(values, marketing:, operating:, flight:))
    end

    private

    def airport(id, field)
      place = Place.joins(:airport).find_by(id:)
      place ? Success(place) : invalid(field)
    end

    def calendar_date(value, field, optional: false)
      return Success(nil) if optional && value.blank?
      return invalid(field) unless value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      Success(Date.iso8601(value))
    rescue Date::Error
      invalid(field)
    end

    def validate_schedule(values, departure:, departure_date:, arrival_date:)
      today = departure.time_zone.present? ? TZInfo::Timezone.get(departure.time_zone).utc_to_local(Time.now.utc).to_date : Date.current
      return invalid(:departure_date) if departure_date > today
      return invalid(:arrival_date) if values[:arrival_time] && !arrival_date

      %i[departure_time arrival_time].each do |key|
        return invalid(key) if values[key] && !values[key].match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)
      end
      Success()
    end

    def carrier(id, field, optional: false)
      return Success(nil) if optional && id.blank?
      return unknown_resolver.call if id.blank?

      airline = Airline.find_by(id:, review_status: %w[approved pending])
      airline ? Success(airline) : invalid(field)
    end

    def schedule_attributes(values, flight:, departure:, arrival:, departure_date:, arrival_date:)
      departure_evidence = event_evidence(:departure, departure, departure_date, values[:departure_time], flight)
      arrival_evidence = event_evidence(:arrival, arrival, arrival_date, values[:arrival_time], flight)
      attributes = departure_evidence.merge(arrival_evidence)
      if attributes[:departure_at] && attributes[:arrival_at] && attributes[:arrival_at] <= attributes[:departure_at]
        return invalid(:arrival_date)
      end

      Success(attributes)
    end

    def event_evidence(event, place, date, time, flight)
      keys = %w[local_at time_zone at offset_seconds resolution].map { |key| "#{event}_#{key}" }
      if same_event?(flight, event, place, date, time)
        return flight.attributes.slice(*keys).symbolize_keys
      end

      TimeZones::ResolveLocalTime.call(date:, time:, zone: place.time_zone)
        .transform_keys { |key| "#{event}_#{key}".to_sym }
    end

    def same_event?(flight, event, place, date, time)
      flight && flight.public_send("#{event}_place_id") == place.id &&
        flight.public_send("#{event}_date") == date &&
        flight.public_send("#{event}_local_at")&.strftime("%H:%M") == time
    end

    def detail_attributes(values, marketing:, operating:, flight:)
      unchanged = flight && flight.flight_detail.marketing_airline_id == marketing.id
      code = if unchanged
        flight.flight_detail.marketing_designator
      else
        Airlines::PickerPresenter.new(airline: marketing, flight_date: Date.iso8601(values[:departure_date]),
          locale: :en).as_json[:preferredCode]
      end
      { marketing_airline: marketing, operating_airline: operating, flight_number: values[:flight_number],
        marketing_designator: code }
    end

    def invalid(field)
      fail_with(code: :validation_error, errors: { field => [ :invalid ] })
    end
  end
end
