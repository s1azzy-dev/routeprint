import { router } from "@inertiajs/react"
import { screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"
import Index from "../../../pages/Flights/Index"
import Show from "../../../pages/Flights/Show"
import { renderInertiaPage } from "../../inertia"
import { formProps } from "./fixtures"

afterEach(() => vi.restoreAllMocks())

describe("Private flight history", () => {
  it("offers the first entry from an empty history", () => {
    renderInertiaPage(Index, {
      copy: formProps.copy,
      flights: [],
      urls: { new: "/flights/new" },
      pagination: { nextUrl: null, previousUrl: null },
    })
    expect(screen.getByText("No flights yet")).toBeVisible()
    expect(screen.getByRole("link", { name: "Add flight" })).toHaveAttribute(
      "href",
      "/flights/new",
    )
  })

  it("renders owned route summaries and server pagination links", () => {
    renderInertiaPage(Index, {
      copy: formProps.copy,
      flights: [formProps.exampleFlight],
      urls: { new: "/flights/new" },
      pagination: {
        nextUrl: "/flights?page=3",
        previousUrl: "/flights?page=1",
      },
    })
    expect(
      screen.getByRole("link", { name: /London Heathrow → Tokyo Haneda/ }),
    ).toHaveAttribute("href", "/flights/1")
    expect(screen.getByRole("link", { name: "Next" })).toHaveAttribute(
      "href",
      "/flights?page=3",
    )
    expect(screen.getByRole("link", { name: "Previous" })).toHaveAttribute(
      "href",
      "/flights?page=1",
    )
  })

  it("displays local schedule and pending/operating carriers with uncertainty", () => {
    const airline = {
      id: "airline-1",
      name: "Example Air",
      countryName: null,
      preferredCode: "AB",
      inactive: true,
      pending: true,
    }
    renderInertiaPage(Show, {
      copy: formProps.copy,
      flight: {
        ...formProps.exampleFlight,
        departureTime: "12:30",
        arrivalDate: "2020-06-02",
        arrivalTime: "09:00",
        marketingAirline: airline,
        operatingAirline: { ...airline, name: "Actual Air" },
        flightNumber: "AB1",
        warnings: [formProps.copy.unresolved],
      },
      urls: { index: "/flights" },
    })
    expect(screen.getByText(/2020-06-01 · 12:30/)).toBeVisible()
    expect(screen.getByText(/2020-06-02 · 09:00/)).toBeVisible()
    expect(screen.getByText("Unverified")).toBeVisible()
    expect(screen.getByText(/Actual Air/)).toBeVisible()
    expect(screen.getByText(formProps.copy.unresolved)).toBeVisible()
  })

  it("cancels deletion without a request and sends only an explicit confirmation", async () => {
    const remove = vi.spyOn(router, "delete").mockImplementation(() => {})
    const user = userEvent.setup()
    renderInertiaPage(Show, {
      copy: formProps.copy,
      flight: formProps.exampleFlight,
      urls: { index: "/flights" },
    })
    await user.click(screen.getByRole("button", { name: "Delete flight" }))
    await user.click(screen.getByRole("button", { name: "Cancel" }))
    expect(remove).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", { name: "Delete flight" }))
    await user.click(screen.getByRole("button", { name: "Yes, delete flight" }))
    expect(remove.mock.calls[0]?.[0]).toBe("/flights/1")
    expect(remove.mock.calls[0]?.[1]?.data).toEqual({ confirmed: true })
  })
})
