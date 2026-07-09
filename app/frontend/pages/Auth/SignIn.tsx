import { Link, useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import {
  AuthForm,
  AuthFormError,
  AuthPageShell,
  AuthSubmit,
  AuthTextField,
} from "@/components/routeprint"

export type SignInProps = {
  copy: {
    email: string
    heading: string
    password: string
    passwordReset: string
    submit: string
    switchLink: string
    switchPrompt: string
  }
  formError: string | null
  urls: {
    passwordReset: string
    signUp: string
    submit: string
  }
  values: {
    email: string | null
  }
}

export default function SignIn({ copy, formError, urls, values }: SignInProps) {
  const { data, post, processing, setData } = useForm({
    session: {
      email: values.email ?? "",
      password: "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(urls.submit)
  }

  return (
    <AuthPageShell
      heading={copy.heading}
      switchHref={urls.signUp}
      switchLink={copy.switchLink}
      switchPrompt={copy.switchPrompt}
    >
      <AuthForm onSubmit={submit}>
        <AuthFormError message={formError} />
        <AuthTextField
          autoComplete="email"
          id="session-email"
          label={copy.email}
          name="session[email]"
          onChange={(email) =>
            setData("session", {
              ...data.session,
              email,
            })
          }
          type="email"
          value={data.session.email}
        />
        <AuthTextField
          autoComplete="current-password"
          id="session-password"
          label={copy.password}
          labelAction={
            <Link
              className="text-sm font-medium text-primary hover:underline"
              href={urls.passwordReset}
            >
              {copy.passwordReset}
            </Link>
          }
          name="session[password]"
          onChange={(password) =>
            setData("session", {
              ...data.session,
              password,
            })
          }
          type="password"
          value={data.session.password}
        />
        <AuthSubmit disabled={processing}>{copy.submit}</AuthSubmit>
      </AuthForm>
    </AuthPageShell>
  )
}
