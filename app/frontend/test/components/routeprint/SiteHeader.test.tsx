import { screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import SiteHeader from "../../../components/routeprint/site-header"
import { renderInertiaPage } from "../../inertia"

const labels = {
  accountMenu: "Account",
  brandName: "Routeprint",
  signIn: "Sign in",
  signOut: "Sign out",
}

const urls = {
  home: "/",
  signIn: "/sign_in",
  signOut: "/sign_out",
}

describe("SiteHeader", () => {
  it("offers sign in to anonymous visitors", () => {
    renderInertiaPage(SiteHeader, {
      authenticated: false,
      labels,
      urls,
    })

    expect(screen.getByRole("banner")).toBeVisible()
    expect(screen.getByRole("link", { name: "Routeprint" })).toHaveAttribute(
      "href",
      "/",
    )
    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/sign_in",
    )
    expect(screen.queryByRole("button", { name: "Account" })).toBeNull()
  })

  it("offers sign out in the authenticated account menu", async () => {
    const user = userEvent.setup()

    renderInertiaPage(SiteHeader, {
      authenticated: true,
      labels,
      urls,
    })

    await user.click(screen.getByRole("button", { name: "Account" }))

    expect(screen.getByRole("menuitem", { name: "Sign out" })).toBeVisible()
    expect(screen.queryByRole("link", { name: "Sign in" })).toBeNull()
  })
})
