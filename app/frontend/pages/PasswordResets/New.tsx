import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import {
  AuthForm,
  AuthPageShell,
  AuthSubmit,
  AuthTextField,
} from "@/components/routeprint"

export type PasswordResetNewProps = {
  copy: {
    email: string
    heading: string
    signInLink: string
    signInPrompt: string
    submit: string
  }
  urls: {
    signIn: string
    submit: string
  }
  values: {
    email: string | null
  }
}

export default function New({ copy, urls, values }: PasswordResetNewProps) {
  const { data, post, processing, setData } = useForm({
    password_reset: {
      email: values.email ?? "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(urls.submit)
  }

  return (
    <AuthPageShell
      heading={copy.heading}
      switchHref={urls.signIn}
      switchLink={copy.signInLink}
      switchPrompt={copy.signInPrompt}
    >
      <AuthForm onSubmit={submit}>
        <AuthTextField
          autoComplete="email"
          id="password-reset-email"
          label={copy.email}
          name="password_reset[email]"
          onChange={(email) =>
            setData("password_reset", {
              ...data.password_reset,
              email,
            })
          }
          type="email"
          value={data.password_reset.email}
        />
        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </AuthForm>
    </AuthPageShell>
  )
}
