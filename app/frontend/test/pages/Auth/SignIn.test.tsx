import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import SignIn, { type SignInProps } from "../../../pages/Auth/SignIn"
import { renderInertiaPage } from "../../inertia"

const props: SignInProps = {
  copy: {
    email: "Email",
    heading: "Sign in",
    password: "Password",
    submit: "Sign in",
    switchLink: "Create an account",
    switchPrompt: "New here?",
  },
  formError: null,
  urls: {
    signUp: "/sign_up",
    submit: "/sign_in",
  },
  values: {
    email: null,
  },
}

describe("Auth/SignIn", () => {
  it("renders the sign-in form with a registration link", () => {
    renderInertiaPage(SignIn, props)

    expect(screen.getByRole("heading", { name: "Sign in" })).toBeVisible()
    expect(screen.getByLabelText("Email")).toHaveAttribute(
      "autocomplete",
      "email",
    )
    expect(screen.getByLabelText("Password")).toHaveAttribute(
      "type",
      "password",
    )
    expect(screen.getByRole("button", { name: "Sign in" })).toHaveAttribute(
      "type",
      "submit",
    )
    expect(
      screen.getByRole("link", { name: "Create an account" }),
    ).toHaveAttribute("href", "/sign_up")
  })

  it("renders a generic error without password values", () => {
    renderInertiaPage(SignIn, {
      ...props,
      formError: "Email or password is incorrect.",
      values: { email: "user@example.com" },
    })

    expect(screen.getByRole("alert")).toHaveTextContent(
      "Email or password is incorrect.",
    )
    expect(screen.queryByDisplayValue("wrong-password-123")).toBeNull()
  })
})
