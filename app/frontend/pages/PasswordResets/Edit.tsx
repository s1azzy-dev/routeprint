import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import {
  AuthForm,
  AuthFormError,
  AuthPageShell,
  AuthSubmit,
  AuthTextField,
} from "@/components/routeprint"

export type PasswordResetEditProps = {
  copy: {
    heading: string
    password: string
    passwordConfirmation: string
    signInLink: string
    signInPrompt: string
    submit: string
  }
  formError: string | null
  urls: {
    signIn: string
  }
}

export default function Edit({
  copy,
  formError,
  urls,
}: PasswordResetEditProps) {
  const { data, patch, processing, setData } = useForm({
    password_reset: {
      password: "",
      password_confirmation: "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    patch(window.location.pathname)
  }

  return (
    <AuthPageShell
      heading={copy.heading}
      switchHref={urls.signIn}
      switchLink={copy.signInLink}
      switchPrompt={copy.signInPrompt}
    >
      <AuthForm onSubmit={submit}>
        <AuthFormError message={formError} />
        <AuthTextField
          autoComplete="new-password"
          id="password-reset-password"
          label={copy.password}
          name="password_reset[password]"
          onChange={(password) =>
            setData("password_reset", {
              ...data.password_reset,
              password,
            })
          }
          type="password"
          value={data.password_reset.password}
        />
        <AuthTextField
          autoComplete="new-password"
          id="password-reset-password-confirmation"
          label={copy.passwordConfirmation}
          name="password_reset[password_confirmation]"
          onChange={(password_confirmation) =>
            setData("password_reset", {
              ...data.password_reset,
              password_confirmation,
            })
          }
          type="password"
          value={data.password_reset.password_confirmation}
        />
        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </AuthForm>
    </AuthPageShell>
  )
}
