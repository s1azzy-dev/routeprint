import { Link, useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export type SignInProps = {
  copy: {
    email: string
    heading: string
    password: string
    submit: string
    switchLink: string
    switchPrompt: string
  }
  formError: string | null
  urls: {
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
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-6 py-12">
        <h1 className="text-3xl font-semibold">{copy.heading}</h1>
        <p className="mt-3 text-sm text-muted-foreground">
          {copy.switchPrompt}{" "}
          <Link
            className="font-medium text-primary hover:underline"
            href={urls.signUp}
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
            <Label htmlFor="session-email">{copy.email}</Label>
            <Input
              autoComplete="email"
              id="session-email"
              name="session[email]"
              onChange={(event) =>
                setData("session", {
                  ...data.session,
                  email: event.target.value,
                })
              }
              type="email"
              value={data.session.email}
            />
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor="session-password">{copy.password}</Label>
            <Input
              autoComplete="current-password"
              id="session-password"
              name="session[password]"
              onChange={(event) =>
                setData("session", {
                  ...data.session,
                  password: event.target.value,
                })
              }
              type="password"
              value={data.session.password}
            />
          </div>

          <Button disabled={processing} size="lg" type="submit">
            {copy.submit}
          </Button>
        </form>
      </section>
    </main>
  )
}
