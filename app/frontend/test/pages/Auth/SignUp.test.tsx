import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import SignUp, { type SignUpProps } from "../../../pages/Auth/SignUp"
import { renderInertiaPage } from "../../inertia"

const props: SignUpProps = {
  copy: {
    email: "Email",
    heading: "Create account",
    locale: "Language",
    password: "Password",
    passwordConfirmation: "Confirm password",
    submit: "Create account",
    switchLink: "Sign in",
    switchPrompt: "Already registered?",
  },
  formError: null,
  localeOptions: [
    { label: "English", value: "en" },
    { label: "Russian", value: "ru" },
  ],
  urls: {
    signIn: "/sign_in",
    submit: "/sign_up",
  },
  values: {
    email: null,
    locale: "en",
  },
}

describe("Auth/SignUp", () => {
  it("renders the sign-up form with locale selection", () => {
    renderInertiaPage(SignUp, props)

    expect(
      screen.getByRole("heading", { name: "Create account" }),
    ).toBeVisible()
    expect(screen.getByLabelText("Email")).toHaveAttribute(
      "autocomplete",
      "email",
    )
    expect(screen.getByLabelText("Password")).toHaveAttribute(
      "autocomplete",
      "new-password",
    )
    expect(screen.getByLabelText("Confirm password")).toHaveAttribute(
      "autocomplete",
      "new-password",
    )
    expect(screen.getByLabelText("Language")).toHaveDisplayValue("English")
    expect(
      screen.getByRole("button", { name: "Create account" }),
    ).toHaveAttribute("type", "submit")
    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/sign_in",
    )
  })
})
