import { router } from "@inertiajs/react"
import { fireEvent, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import Form from "../../../pages/Flights/Form"
import { renderInertiaPage } from "../../inertia"
import { formProps } from "./fixtures"

afterEach(() => vi.restoreAllMocks())

describe("Manual flight form", () => {
  it("submits the edited date and optional schedule without browser timezone conversion", async () => {
    const post = vi.spyOn(router, "post").mockImplementation(() => {})
    const user = userEvent.setup()
    renderInertiaPage(Form, formProps)
    fireEvent.input(screen.getByLabelText("Departure date"), {
      target: { value: "2020-06-02" },
    })
    fireEvent.input(screen.getByLabelText("Departure time (optional)"), {
      target: { value: "12:30" },
    })
    await user.click(screen.getByRole("button", { name: "Save flight" }))
    expect(post.mock.calls[0]?.[1]).toEqual({
      flight: {
        ...formProps.values,
        departure_date: "2020-06-02",
        departure_time: "12:30",
        confirmed_duplicate: false,
      },
    })
  })

  it("uses the edit endpoint and preserves unknown carrier values", async () => {
    const patch = vi.spyOn(router, "patch").mockImplementation(() => {})
    const user = userEvent.setup()
    renderInertiaPage(Form, {
      ...formProps,
      editing: true,
      urls: { ...formProps.urls, submit: "/flights/1" },
    })
    await user.type(screen.getByLabelText("Flight number (optional)"), "AB123")
    await user.click(screen.getByRole("button", { name: "Save flight" }))
    expect(patch.mock.calls[0]?.[0]).toBe("/flights/1")
    expect(patch.mock.calls[0]?.[1]).toEqual({
      flight: {
        ...formProps.values,
        flight_number: "AB123",
        confirmed_duplicate: false,
      },
    })
  })

  it("sends explicit confirmation for an intentional similar flight", async () => {
    const post = vi.spyOn(router, "post").mockImplementation(() => {})
    const user = userEvent.setup()
    renderInertiaPage(Form, {
      ...formProps,
      duplicates: [formProps.exampleFlight],
    })
    await user.click(
      screen.getByRole("button", { name: "Save another flight" }),
    )
    expect(post.mock.calls[0]?.[1]).toEqual({
      flight: { ...formProps.values, confirmed_duplicate: true },
    })
  })
  it("requires only route and date and retains server errors and partial schedule", () => {
    renderInertiaPage(Form, {
      ...formProps,
      formErrors: { arrival_date: "Enter an arrival date" },
    })
    expect(screen.getByLabelText("Departure date")).toBeRequired()
    expect(screen.getByLabelText("From")).toHaveAccessibleDescription(
      /London Heathrow/,
    )
    expect(
      screen.getByLabelText("Departure time (optional)"),
    ).not.toBeRequired()
    expect(screen.getByLabelText("Departure time (optional)")).toHaveValue("")
    expect(screen.getByText("Enter an arrival date")).toBeVisible()
    expect(screen.getByRole("button", { name: "Save flight" })).toBeEnabled()
  })

  it("submits a date-only form with its stable creation identity", async () => {
    const post = vi.spyOn(router, "post").mockImplementation(() => {})
    const user = userEvent.setup()
    renderInertiaPage(Form, formProps)
    await user.click(screen.getByRole("button", { name: "Save flight" }))
    const [url, payload] = post.mock.calls[0] ?? []
    expect(url).toBe("/flights")
    expect(payload).toEqual({
      flight: { ...formProps.values, confirmed_duplicate: false },
    })
  })

  it("requires deliberate confirmation of a duplicate and clears it after date changes", async () => {
    const user = userEvent.setup()
    renderInertiaPage(Form, {
      ...formProps,
      duplicates: [formProps.exampleFlight],
    })
    expect(
      screen.getByRole("button", { name: "Save another flight" }),
    ).toBeVisible()
    await user.clear(screen.getByLabelText("Departure date"))
    expect(
      screen.queryByRole("button", { name: "Save another flight" }),
    ).not.toBeInTheDocument()
  })
})
