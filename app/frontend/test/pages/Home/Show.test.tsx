import { screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import HomeShow from "../../../pages/Home/Show"
import { renderInertiaPage } from "../../inertia"

vi.mock("../../../components/routeprint/route-map", () => ({
  RouteMap: () => <div data-testid="route-map" />,
}))

describe("HomeShow", () => {
  it("renders through the Inertia test harness", () => {
    renderInertiaPage(HomeShow, {})

    expect(screen.getByTestId("route-map")).toBeVisible()
  })
})
