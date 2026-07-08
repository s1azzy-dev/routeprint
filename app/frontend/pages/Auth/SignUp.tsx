import { Link, useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

type LocaleOption = {
  label: string
  value: string
}

export type SignUpProps = {
  copy: {
    email: string
    heading: string
    locale: string
    password: string
    passwordConfirmation: string
    submit: string
    switchLink: string
    switchPrompt: string
  }
  formError: string | null
  localeOptions: LocaleOption[]
  urls: {
    signIn: string
    submit: string
  }
  values: {
    email: string | null
    locale: string
  }
}

export default function SignUp({
  copy,
  formError,
  localeOptions,
  urls,
  values,
}: SignUpProps) {
  const { data, post, processing, setData } = useForm({
    registration: {
      email: values.email ?? "",
      locale: values.locale,
      password: "",
      password_confirmation: "",
    },
  })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(urls.submit)
  }

  return (
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-6 py-12">
        <h1 className="text-3xl font-semibold">{copy.heading}</h1>
        <p className="mt-3 text-sm text-muted-foreground">
          {copy.switchPrompt}{" "}
          <Link
            className="font-medium text-primary hover:underline"
            href={urls.signIn}
          >
            {copy.switchLink}
          </Link>
        </p>

        <form className="mt-8 flex flex-col gap-5" onSubmit={submit}>
          {formError ? (
            <p
              className="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive"
              role="alert"
            >
              {formError}
            </p>
          ) : null}

          <div className="flex flex-col gap-2">
            <Label htmlFor="registration-email">{copy.email}</Label>
            <Input
              autoComplete="email"
              id="registration-email"
              name="registration[email]"
              onChange={(event) =>
                setData("registration", {
                  ...data.registration,
                  email: event.target.value,
                })
              }
              type="email"
              value={data.registration.email}
            />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="registration-password">{copy.password}</Label>
            <Input
              autoComplete="new-password"
              id="registration-password"
              name="registration[password]"
              onChange={(event) =>
                setData("registration", {
                  ...data.registration,
                  password: event.target.value,
                })
              }
              type="password"
              value={data.registration.password}
            />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="registration-password-confirmation">
              {copy.passwordConfirmation}
            </Label>
            <Input
              autoComplete="new-password"
              id="registration-password-confirmation"
              name="registration[password_confirmation]"
              onChange={(event) =>
                setData("registration", {
                  ...data.registration,
                  password_confirmation: event.target.value,
                })
              }
              type="password"
              value={data.registration.password_confirmation}
            />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="registration-locale">{copy.locale}</Label>
            <select
              className="h-8 w-full rounded-lg border border-input bg-transparent px-2.5 py-1 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
              id="registration-locale"
              name="registration[locale]"
              onChange={(event) =>
                setData("registration", {
                  ...data.registration,
                  locale: event.target.value,
                })
              }
              value={data.registration.locale}
            >
              {localeOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>

          <Button disabled={processing} size="lg" type="submit">
            {copy.submit}
          </Button>
        </form>
      </section>
    </main>
  )
}
