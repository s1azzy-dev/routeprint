import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"
import AirportPicker from "../../../pages/Flights/airport-picker"
import { formProps } from "./fixtures"

afterEach(() => vi.unstubAllGlobals())

describe("Airport selection", () => {
  it("allows search and candidate selection entirely from the keyboard", async () => {
    const airport = formProps.exampleFlight.departureAirport
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ airports: [airport] }),
      }),
    )
    const change = vi.fn()
    const user = userEvent.setup()
    render(
      <AirportPicker
        id="origin"
        value={null}
        onChange={change}
        copy={formProps.copy}
        searchUrl="/airports/search"
      />,
    )
    await user.click(screen.getByRole("button", { name: "Choose airport" }))
    await user.type(
      screen.getByLabelText(formProps.copy.search_label),
      "LHR{Enter}",
    )
    await screen.findByRole("option", { name: /London Heathrow/ })
    await user.keyboard("{ArrowDown}{Enter}")
    expect(change).toHaveBeenCalledWith(airport)
  })
  it("searches and selects closed historical airports without submitting a parent form", async () => {
    const airport = {
      ...formProps.exampleFlight.departureAirport,
      closed: true,
    }
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ airports: [airport] }),
      }),
    )
    const change = vi.fn()
    const submit = vi.fn()
    render(
      <form onSubmit={submit}>
        <AirportPicker
          id="origin"
          value={null}
          onChange={change}
          copy={formProps.copy}
          searchUrl="/airports/search"
        />
      </form>,
    )
    const user = userEvent.setup()
    await user.click(screen.getByRole("button", { name: "Choose airport" }))
    await user.type(screen.getByLabelText(formProps.copy.search_label), "LHR")
    await user.click(screen.getByRole("button", { name: "Search airports" }))
    expect(await screen.findByText("Closed")).toBeVisible()
    await user.click(screen.getByRole("option", { name: /London Heathrow/ }))
    expect(change).toHaveBeenCalledWith(airport)
    expect(submit).not.toHaveBeenCalled()
  })

  it("shows recoverable network feedback", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("offline")))
    const user = userEvent.setup()
    render(
      <AirportPicker
        id="origin"
        value={null}
        onChange={() => {}}
        copy={formProps.copy}
        searchUrl="/airports/search"
      />,
    )
    await user.click(screen.getByRole("button", { name: "Choose airport" }))
    await user.type(screen.getByLabelText(formProps.copy.search_label), "LHR")
    await user.click(screen.getByRole("button", { name: "Search airports" }))
    expect(await screen.findByText(formProps.copy.search_error)).toBeVisible()
  })
})
