import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import AirlinePicker, {
  type AirlineChoice,
  type AirlinePickerCopy,
} from "../../../components/routeprint/airline-picker"

const copy: AirlinePickerCopy = {
  addAction: "Add airline",
  addDescription: "Add a shared unverified airline.",
  addTitle: "Add missing airline",
  cancel: "Back to search",
  confirmation: "I checked the search results",
  createAction: "Add airline",
  creating: "Adding airline…",
  dialogDescription: "Search approved and unverified airlines.",
  dialogTitle: "Choose airline",
  fields: {
    code: { description: "Two or three characters", label: "Airline code" },
    country: { label: "Country", none: "Not specified" },
    name: { label: "Airline name" },
  },
  inactive: "Inactive",
  noResults: "No airlines found",
  pending: "Unverified",
  searchAction: "Search airlines",
  searchError: "Could not search. Try again.",
  searchLabel: "Airline name or code",
  searchPlaceholder: "Start typing",
  searching: "Searching…",
  submitError: "Could not add the airline. Check the fields and try again.",
  triggerPlaceholder: "Choose airline",
  validation: {
    code: "Use a two-character or three-letter code.",
    confirmation: "Confirm that you checked the results.",
    country: "Choose a valid country.",
    name: "Enter an airline name.",
  },
}

const choice = {
  countryName: "United Kingdom",
  id: "airline-1",
  inactive: true,
  name: "Example Air",
  pending: true,
  preferredCode: "E1",
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe("AirlinePicker", () => {
  it("searches and selects a clearly labelled candidate", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValue(jsonResponse({ airlines: [choice] }))
    const onChange = vi.fn()
    vi.stubGlobal("fetch", fetchMock)
    const user = userEvent.setup()

    renderPicker({ onChange })
    await user.click(screen.getByRole("button", { name: "Choose airline" }))
    await user.type(screen.getByLabelText("Airline name or code"), "Example")
    await user.click(screen.getByRole("button", { name: "Search airlines" }))

    expect(await screen.findByText("Example Air")).toBeVisible()
    expect(screen.getByText("Unverified")).toBeVisible()
    expect(screen.getByText("Inactive")).toBeVisible()
    await user.click(screen.getByRole("option", { name: /Example Air/ }))
    expect(onChange).toHaveBeenCalledWith(choice)
  })

  it("submits a confirmed missing airline and selects the returned candidate", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse({ airlines: [] }))
      .mockResolvedValueOnce(
        jsonResponse({ airline: choice, reused: false }, 201),
      )
    const onChange = vi.fn()
    vi.stubGlobal("fetch", fetchMock)
    const user = userEvent.setup()

    renderPicker({ onChange })
    await user.click(screen.getByRole("button", { name: "Choose airline" }))
    await user.type(
      screen.getByLabelText("Airline name or code"),
      "Example Air",
    )
    await user.click(screen.getByRole("button", { name: "Search airlines" }))
    await user.click(await screen.findByRole("button", { name: "Add airline" }))
    await user.type(screen.getByLabelText("Airline code"), "E1")
    await user.click(screen.getByLabelText("I checked the search results"))
    await user.click(screen.getByRole("button", { name: "Add airline" }))

    expect(onChange).toHaveBeenCalledWith(choice)
    expect(fetchMock).toHaveBeenLastCalledWith(
      "/airlines",
      expect.objectContaining({
        body: JSON.stringify({
          airline: {
            code: "E1",
            confirmed: true,
            country_id: null,
            name: "Example Air",
          },
        }),
        method: "POST",
      }),
    )
  })
})

function renderPicker({
  onChange,
}: {
  onChange: (value: AirlineChoice) => void
}) {
  return render(
    <AirlinePicker
      copy={copy}
      countries={[]}
      onChange={onChange}
      searchUrl="/airlines/search"
      submitUrl="/airlines"
      value={null}
    />,
  )
}

function jsonResponse(body: unknown, status = 200) {
  return {
    json: () => Promise.resolve(body),
    ok: status >= 200 && status < 300,
    status,
  } as Response
}
