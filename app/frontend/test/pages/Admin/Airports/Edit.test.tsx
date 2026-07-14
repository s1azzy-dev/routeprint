import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Edit from "../../../../pages/Admin/Airports/Edit"
import { renderInertiaPage } from "../../../inertia"

const props = {
  airport: {
    countryCode: "GB",
    icaoCode: "EGLL",
    iataCode: "LHR",
    municipalityName: "London",
    name: "London Heathrow",
    operationalStatus: "active",
    placeId: "place-1",
    regionCode: "GB-ENG",
    timeZone: "Europe/London",
  },
  copy: {
    back: "Back to airports",
    description: "Update the airport.",
    fields: {
      country_code: { label: "Country code", placeholder: "GB" },
      icao_code: { label: "ICAO code", placeholder: "EGLL" },
      iata_code: { label: "IATA code", placeholder: "LHR" },
      municipality_name: { label: "Municipality", placeholder: "London" },
      name: { label: "Airport name", placeholder: "London Heathrow" },
      operational_status: {
        label: "Operational status",
        placeholder: "Active",
      },
      region_code: { label: "Region code", placeholder: "GB-ENG" },
      time_zone: { label: "Time zone", placeholder: "Europe/London" },
    },
    formHeading: "Airport details",
    heading: "Edit airport",
    submit: "Save airport",
    title: "Edit airport",
    toolbarLabel: "Admin",
  },
  formErrors: {},
  navigation: { sections: [] },
  options: {
    operationalStatuses: [
      { label: "Active", value: "active" },
      { label: "Closed", value: "closed" },
      { label: "Unknown", value: "unknown" },
    ],
  },
  urls: { index: "/admin/airports", update: "/admin/airports/place-1" },
}

describe("Admin airport edit", () => {
  it("renders the typed edit form and save action", () => {
    renderInertiaPage(Edit, props)

    expect(screen.getByRole("heading", { name: "Edit airport" })).toBeVisible()
    expect(screen.getByLabelText("Airport name")).toHaveValue("London Heathrow")
    expect(screen.getByLabelText("IATA code")).toHaveValue("LHR")
    expect(screen.getByRole("button", { name: "Save airport" })).toBeVisible()
  })

  it("renders field validation feedback from Rails", () => {
    renderInertiaPage(Edit, {
      ...props,
      formErrors: { time_zone: "is not a valid IANA timezone" },
    })

    expect(screen.getByRole("alert")).toHaveTextContent(
      "is not a valid IANA timezone",
    )
  })
})
