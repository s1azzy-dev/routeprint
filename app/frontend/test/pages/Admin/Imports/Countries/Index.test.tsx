import { screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { router } from "@inertiajs/react"

import Index from "../../../../../pages/Admin/Imports/Countries/Index"
import { renderInertiaPage } from "../../../../inertia"

const props = {
  copy: {
    actions: { start: "Start refresh" },
    columns: {
      mode: "Mode",
      parameters: "Parameters",
      progress: "Progress",
      source: "Source",
      status: "Status",
      timestamps: "Timestamps",
    },
    description: "Review country imports.",
    emptyDescription: "Start a refresh.",
    emptyTitle: "No country imports yet",
    heading: "Country imports",
    pagination: {
      label: "Country import pages",
      next: "Next",
      previous: "Previous",
      summary: "Showing 1-1 of 1 runs",
    },
    progress: { failed: "failed", issues: "issues" },
    statuses: { succeeded: "Succeeded" },
    tableCaption: "Country source runs",
    timestamps: { pending: "Still running" },
    title: "Country imports",
    toolbarLabel: "Admin",
  },
  navigation: { sections: [] },
  pagination: {
    currentPage: 1,
    nextUrl: null,
    previousUrl: null,
    totalCount: 1,
    totalPages: 1,
  },
  runs: [
    {
      completedCount: 1,
      createdAt: "2026-07-16T08:00:00Z",
      failedCount: 0,
      finishedAt: "2026-07-16T08:05:00Z",
      id: 1,
      issueCount: 0,
      mode: "full",
      parameters: { cldrRelease: "48.2.1" },
      sourceKey: "country_catalog",
      startedAt: null,
      status: "succeeded",
      totalCount: 2,
    },
  ],
  urls: {
    create: "/admin/imports/countries",
    index: "/admin/imports/countries",
  },
}

describe("Admin country imports index", () => {
  it("renders country source history through the shared import table", () => {
    renderInertiaPage(Index, props, {}, "/admin/imports/countries")

    expect(screen.getByRole("main", { name: "Country imports" })).toBeVisible()
    expect(screen.getByText("country_catalog")).toBeVisible()
    expect(screen.getByText(/cldrRelease:/)).toBeVisible()
  })

  it("starts the composite refresh from the page action", async () => {
    const user = userEvent.setup()
    const post = vi.spyOn(router, "post").mockImplementation(() => undefined)

    renderInertiaPage(Index, props)
    await user.click(screen.getByRole("button", { name: "Start refresh" }))

    expect(post).toHaveBeenCalledWith("/admin/imports/countries")
    post.mockRestore()
  })
})
