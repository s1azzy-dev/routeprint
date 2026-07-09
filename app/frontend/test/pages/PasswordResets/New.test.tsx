import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import New, {
  type PasswordResetNewProps,
} from "../../../pages/PasswordResets/New"
import { renderInertiaPage } from "../../inertia"

const props: PasswordResetNewProps = {
  copy: {
    email: "Email",
    heading: "Reset password",
    signInLink: "Back to sign in",
    signInPrompt: "Remembered it?",
    submit: "Send reset link",
  },
  urls: {
    signIn: "/sign_in",
    submit: "/password-reset",
  },
  values: {
    email: null,
  },
}

describe("PasswordResets/New", () => {
  it("renders the reset request form", () => {
    renderInertiaPage(New, props)

    expect(
      screen.getByRole("heading", { name: "Reset password" }),
    ).toBeVisible()
    expect(screen.getByLabelText("Email")).toHaveAttribute(
      "autocomplete",
      "email",
    )
    expect(
      screen.getByRole("button", { name: "Send reset link" }),
    ).toHaveAttribute("type", "submit")
    expect(
      screen.getByRole("link", { name: "Back to sign in" }),
    ).toHaveAttribute("href", "/sign_in")
  })
})
