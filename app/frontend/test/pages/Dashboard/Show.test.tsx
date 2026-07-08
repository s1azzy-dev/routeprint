import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import DashboardShow, {
  type DashboardShowProps,
} from "../../../pages/Dashboard/Show"
import { renderInertiaPage } from "../../inertia"

const props: DashboardShowProps = {
  copy: {
    email: "user@example.com",
    heading: "Dashboard",
    signOut: "Sign out",
  },
  urls: {
    signOut: "/sign_out",
  },
}

describe("Dashboard/Show", () => {
  it("renders the protected dashboard without auth tokens", () => {
    const { container } = renderInertiaPage(DashboardShow, props)

    expect(screen.getByRole("heading", { name: "Dashboard" })).toBeVisible()
    expect(screen.getByText("user@example.com")).toBeVisible()
    expect(screen.getByRole("button", { name: "Sign out" })).toBeVisible()
    expect(container.textContent).not.toContain("token")
  })
})
