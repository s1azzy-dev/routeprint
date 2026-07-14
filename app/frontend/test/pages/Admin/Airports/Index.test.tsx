import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Index from "../../../../pages/Admin/Airports/Index"
import { renderInertiaPage } from "../../../inertia"

const props = {
  airports: [
    {
      countryCode: "GB",
      destroyUrl: "/admin/airports/place-1",
      editUrl: "/admin/airports/place-1/edit",
      iataCode: "LHR",
      icaoCode: "EGLL",
      municipalityName: "London",
      name: "London Heathrow",
      operationalStatus: "active",
      placeId: "place-1",
      timeZone: "Europe/London",
    },
  ],
  copy: {
    actions: { cancel: "Cancel", delete: "Delete", edit: "Edit" },
    columns: {
      actions: "Actions",
      airport: "Airport",
      codes: "Codes",
      country: "Country",
      status: "Status",
      timeZone: "Time zone",
    },
    description: "Maintain airports.",
    emptyDescription: "No airports.",
    emptyTitle: "No airports found",
    heading: "Airports",
    pagination: {
      label: "Airport pages",
      next: "Next",
      previous: "Previous",
      summary: "Showing 1-1 of 1 airports",
    },
    tableCaption: "Canonical airports",
    title: "Airports",
    toolbarLabel: "Admin",
    statuses: { active: "Active", closed: "Closed", unknown: "Unknown" },
  },
  navigation: {
    sections: [
      {
        items: [
          {
            current: true,
            icon: "airports" as const,
            key: "airports",
            label: "Airports",
            url: "/admin/airports",
          },
        ],
        key: "primary",
      },
    ],
  },
  pagination: {
    currentPage: 1,
    nextUrl: null,
    previousUrl: null,
    totalCount: 1,
    totalPages: 1,
  },
  urls: { index: "/admin/airports" },
}

describe("Admin airport index", () => {
  it("renders the admin shell, table row, and edit action", () => {
    renderInertiaPage(Index, props)

    expect(screen.getByRole("main", { name: "Airports" })).toBeVisible()
    expect(screen.getByRole("link", { name: "Airports" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(screen.getByText("London Heathrow")).toBeVisible()
    expect(
      screen.getByRole("link", { name: "Edit: London Heathrow" }),
    ).toHaveAttribute("href", "/admin/airports/place-1/edit")
  })

  it("renders an accessible empty state", () => {
    renderInertiaPage(Index, { ...props, airports: [] })

    expect(screen.getByText("No airports found")).toBeVisible()
    expect(screen.getByText("No airports.")).toBeVisible()
    expect(screen.queryByRole("table")).toBeNull()
  })
})
