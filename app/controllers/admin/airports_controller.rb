module Admin
  class AirportsController < BaseController
    include Pagy::Method

    PAGE_SIZE = 25

    def index
      authorize Airport, :index?, policy_class: Admin::AirportPolicy
      pagy, airports = pagy(:offset, airports_scope, limit: PAGE_SIZE)

      render inertia: "Admin/Airports/Index", props: index_props(pagy:, airports:)
    end

    def edit
      airport = airport_record
      authorize airport, :update?, policy_class: Admin::AirportPolicy

      render inertia: "Admin/Airports/Edit", props: edit_props(airport:)
    end

    def update
      airport = airport_record
      authorize airport, :update?, policy_class: Admin::AirportPolicy
      result = Admin::UpdateAirport.call(input: { airport:, attributes: airport_params })

      if result.success?
        redirect_to admin_airports_path, notice: t("admin.airports.flash.updated"), status: :see_other
      else
        render inertia: "Admin/Airports/Edit",
          props: edit_props(airport:, form_errors: result.failure[:errors]),
          status: :unprocessable_content
      end
    end

    def destroy
      airport = airport_record
      authorize airport, :destroy?, policy_class: Admin::AirportPolicy
      result = Admin::DeleteAirport.call(input: { airport: })

      if result.success?
        redirect_to admin_airports_path, notice: t("admin.airports.flash.deleted"), status: :see_other
      else
        redirect_to admin_airports_path, alert: t("admin.airports.flash.delete_restricted")
      end
    end

    private

    def airports_scope
      Airport.joins(:place).includes(:place).order("places.name ASC", place_id: :asc)
    end

    def airport_record
      @airport_record ||= Airport.includes(:place).find_by!(place_id: params[:place_id])
    end

    def index_props(pagy:, airports:)
      {
        copy: index_copy(pagy:),
        navigation: admin_navigation(current: "airports"),
        pagination: pagination_props(pagy),
        urls: { index: admin_airports_path },
        airports: airports.map { |airport| airport_row_props(airport) }
      }
    end

    def edit_props(airport:, form_errors: {})
      {
        airport: airport_detail_props(airport),
        copy: edit_copy,
        formErrors: form_errors_props(form_errors),
        navigation: admin_navigation(current: "airports"),
        options: {
          operationalStatuses: Airport::OPERATIONAL_STATUSES.map do |status|
            option_props("admin.airports.statuses.#{status}", status)
          end
        },
        urls: {
          index: admin_airports_path,
          update: admin_airport_path(airport.place_id)
        }
      }
    end

    def airport_row_props(airport)
      {
        placeId: airport.place_id,
        name: airport.place.name,
        municipalityName: airport.place.municipality_name,
        countryCode: airport.place.country_code,
        iataCode: airport.iata_code,
        icaoCode: airport.icao_code,
        operationalStatus: airport.operational_status,
        timeZone: airport.place.time_zone,
        editUrl: edit_admin_airport_path(airport.place_id),
        destroyUrl: admin_airport_path(airport.place_id)
      }
    end

    def airport_detail_props(airport)
      airport_row_props(airport).merge(
        regionCode: airport.place.region_code,
        continentCode: airport.place.continent_code
      )
    end

    def pagination_props(pagy)
      urls = pagy.urls_hash

      {
        currentPage: pagy.page,
        nextUrl: urls[:next],
        previousUrl: urls[:prev],
        totalCount: pagy.count,
        totalPages: pagy.last
      }
    end

    def index_copy(pagy:)
      {
        title: t("admin.airports.index.title"),
        heading: t("admin.airports.index.heading"),
        description: t("admin.airports.index.description"),
        toolbarLabel: t("admin.shell.toolbar_label"),
        emptyTitle: t("admin.airports.index.empty_title"),
        emptyDescription: t("admin.airports.index.empty_description"),
        tableCaption: t("admin.airports.index.table_caption"),
        columns: {
          airport: t("admin.airports.index.columns.airport"),
          codes: t("admin.airports.index.columns.codes"),
          country: t("admin.airports.index.columns.country"),
          status: t("admin.airports.index.columns.status"),
          timeZone: t("admin.airports.index.columns.time_zone"),
          actions: t("admin.airports.index.columns.actions")
        },
        actions: {
          cancel: t("admin.airports.actions.cancel"),
          edit: t("admin.airports.actions.edit"),
          delete: t("admin.airports.actions.delete")
        },
        statuses: Airport::OPERATIONAL_STATUSES.to_h do |status|
          [ status, t("admin.airports.statuses.#{status}") ]
        end,
        pagination: pagination_copy(pagy:)
      }
    end

    def edit_copy
      {
        title: t("admin.airports.edit.title"),
        heading: t("admin.airports.edit.heading"),
        description: t("admin.airports.edit.description"),
        toolbarLabel: t("admin.shell.toolbar_label"),
        back: t("admin.airports.edit.back"),
        formHeading: t("admin.airports.edit.form_heading"),
        submit: t("admin.airports.edit.submit"),
        fields: {
          name: field_copy("name"),
          municipalityName: field_copy("municipality_name"),
          countryCode: field_copy("country_code"),
          regionCode: field_copy("region_code"),
          timeZone: field_copy("time_zone"),
          operationalStatus: field_copy("operational_status"),
          iataCode: field_copy("iata_code"),
          icaoCode: field_copy("icao_code")
        }
      }
    end

    def pagination_copy(pagy:)
      {
        label: t("admin.airports.index.pagination.label"),
        previous: t("admin.airports.index.pagination.previous"),
        next: t("admin.airports.index.pagination.next"),
        summary: t(
          "admin.airports.index.pagination.summary",
          from: pagy.from,
          to: pagy.to,
          count: pagy.count
        )
      }
    end

    def field_copy(field)
      {
        label: t("admin.airports.edit.fields.#{field}.label"),
        placeholder: t("admin.airports.edit.fields.#{field}.placeholder")
      }
    end

    def option_props(key, value)
      { label: t(key), value: }
    end

    def form_errors_props(errors)
      errors.to_h.each_with_object({}) do |(attribute, messages), props|
        props[attribute.to_s] = Array(messages).join(", ")
      end
    end

    def airport_params
      params.expect(
        airport: %i[
          name municipality_name country_code region_code time_zone
          operational_status iata_code icao_code
        ]
      ).to_h.symbolize_keys
    end
  end
end
