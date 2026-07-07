import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import HomeShow from "../../../pages/Home/Show"
import { renderInertiaPage } from "../../inertia"

describe("HomeShow", () => {
  it("renders through the Inertia test harness", () => {
    renderInertiaPage(HomeShow, { appName: "Routeprint" })

    expect(
      screen.getByRole("heading", { level: 1, name: "Routeprint" }),
    ).toBeVisible()
    expect(screen.getByText("Rails / Inertia / React")).toBeVisible()
  })
})
