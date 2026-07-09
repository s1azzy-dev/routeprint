import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Edit, {
  type PasswordResetEditProps,
} from "../../../pages/PasswordResets/Edit"
import { renderInertiaPage } from "../../inertia"

const props: PasswordResetEditProps = {
  copy: {
    heading: "Choose a new password",
    password: "Password",
    passwordConfirmation: "Confirm password",
    signInLink: "Back to sign in",
    signInPrompt: "Need the sign-in page?",
    submit: "Update password",
  },
  formError: null,
  urls: {
    signIn: "/sign_in",
  },
}

describe("PasswordResets/Edit", () => {
  it("renders the reset consume form", () => {
    renderInertiaPage(Edit, props)

    expect(
      screen.getByRole("heading", { name: "Choose a new password" }),
    ).toBeVisible()
    expect(screen.getByLabelText("Password")).toHaveAttribute(
      "autocomplete",
      "new-password",
    )
    expect(screen.getByLabelText("Confirm password")).toHaveAttribute(
      "autocomplete",
      "new-password",
    )
    expect(
      screen.getByRole("button", { name: "Update password" }),
    ).toHaveAttribute("type", "submit")
    expect(
      screen.getByRole("link", { name: "Back to sign in" }),
    ).toHaveAttribute("href", "/sign_in")
  })

  it("renders a generic reset error", () => {
    renderInertiaPage(Edit, {
      ...props,
      formError: "That password reset link is invalid or expired.",
    })

    expect(screen.getByRole("alert")).toHaveTextContent(
      "That password reset link is invalid or expired.",
    )
  })
})
