import { screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { router } from "@inertiajs/react"

import Index from "../../../../../pages/Admin/Imports/Airports/Index"
import { renderInertiaPage } from "../../../../inertia"

const props = {
  copy: {
    actions: { start: "Start import" },
    columns: {
      mode: "Mode",
      parameters: "Parameters",
      progress: "Progress",
      source: "Source",
      status: "Status",
      timestamps: "Timestamps",
    },
    description: "Review airport imports.",
    emptyDescription: "Start an import.",
    emptyTitle: "No airport imports yet",
    heading: "Airport imports",
    pagination: {
      label: "Airport import pages",
      next: "Next",
      previous: "Previous",
      summary: "Showing 1-1 of 1 imports",
    },
    progress: { failed: "failed", issues: "issues" },
    statuses: { succeeded: "Succeeded" },
    tableCaption: "OurAirports airport imports",
    timestamps: { pending: "Still running" },
    title: "Airport imports",
    toolbarLabel: "Admin",
  },
  navigation: {
    sections: [
      {
        items: [
          {
            current: false,
            icon: "airports" as const,
            key: "airports",
            label: "Airports",
            url: "/admin/airports",
          },
        ],
        key: "primary",
      },
      {
        items: [
          {
            current: true,
            icon: "airports" as const,
            key: "import_airports",
            label: "Airports",
            url: "/admin/imports/airports",
          },
        ],
        key: "imports",
        label: "Imports",
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
  runs: [
    {
      completedCount: 1,
      createdAt: "2026-07-15T08:00:00Z",
      failedCount: 0,
      finishedAt: "2026-07-15T08:05:00Z",
      id: 1,
      issueCount: 0,
      mode: "full",
      parameters: {
        parserVersion: "1",
        sourceUrl: "https://ourairports.com/data/airports.csv",
      },
      sourceKey: "ourairports_airports",
      startedAt: "2026-07-15T08:00:01Z",
      status: "succeeded",
      totalCount: 1,
    },
  ],
  urls: {
    create: "/admin/imports/airports",
    index: "/admin/imports/airports",
  },
}

describe("Admin airport imports index", () => {
  it("renders the imports navigation, table, progress, and status", () => {
    renderInertiaPage(Index, props, {}, "/admin/imports/airports")

    expect(screen.getByRole("main", { name: "Airport imports" })).toBeVisible()
    const adminNavigation = screen.getByRole("navigation", { name: "Admin" })
    expect(
      within(adminNavigation)
        .getAllByRole("link", { name: "Airports" })
        .find((link) => link.getAttribute("aria-current") === "page"),
    ).toBeDefined()
    expect(screen.getByText("ourairports_airports")).toBeVisible()
    expect(screen.getByText("Succeeded")).toBeVisible()
    expect(screen.getByText("1/1")).toBeVisible()
    expect(screen.getByText(/sourceUrl:/)).toBeVisible()
  })

  it("starts an import from the page action", async () => {
    const user = userEvent.setup()
    const post = vi.spyOn(router, "post").mockImplementation(() => undefined)

    renderInertiaPage(Index, props)
    await user.click(screen.getByRole("button", { name: "Start import" }))

    expect(post).toHaveBeenCalledWith("/admin/imports/airports")
    post.mockRestore()
  })

  it("renders an accessible empty state", () => {
    renderInertiaPage(Index, { ...props, runs: [] })

    expect(screen.getByText("No airport imports yet")).toBeVisible()
    expect(screen.getByText("Start an import.")).toBeVisible()
    expect(screen.queryByRole("table")).toBeNull()
  })
})
