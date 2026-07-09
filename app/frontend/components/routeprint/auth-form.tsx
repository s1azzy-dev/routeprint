import { Link } from "@inertiajs/react"
import type { FormEventHandler, ReactNode } from "react"

import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"

type AuthPageShellProps = {
  children: ReactNode
  heading: string
  switchHref: string
  switchLink: string
  switchPrompt: string
}

export function AuthPageShell({
  children,
  heading,
  switchHref,
  switchLink,
  switchPrompt,
}: AuthPageShellProps) {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-6 py-12">
        <h1 className="text-3xl font-semibold">{heading}</h1>
        <p className="mt-3 text-sm text-muted-foreground">
          {switchPrompt}{" "}
          <Link
            className="font-medium text-primary hover:underline"
            href={switchHref}
          >
            {switchLink}
          </Link>
        </p>
        {children}
      </section>
    </main>
  )
}

type AuthFormProps = {
  children: ReactNode
  onSubmit: FormEventHandler<HTMLFormElement>
}

export function AuthForm({ children, onSubmit }: AuthFormProps) {
  return (
    <form className="mt-8" onSubmit={onSubmit}>
      <FieldGroup>{children}</FieldGroup>
    </form>
  )
}

type AuthTextFieldProps = {
  autoComplete: string
  id: string
  label: string
  labelAction?: ReactNode
  name: string
  onChange: (value: string) => void
  type: "email" | "password" | "text"
  value: string
}

export function AuthTextField({
  autoComplete,
  id,
  label,
  labelAction,
  name,
  onChange,
  type,
  value,
}: AuthTextFieldProps) {
  return (
    <Field>
      <div className="flex items-center justify-between gap-3">
        <FieldLabel htmlFor={id}>{label}</FieldLabel>
        {labelAction}
      </div>
      <Input
        autoComplete={autoComplete}
        id={id}
        name={name}
        onChange={(event) => onChange(event.target.value)}
        type={type}
        value={value}
      />
    </Field>
  )
}

type AuthFormErrorProps = {
  message: string | null
}

export function AuthFormError({ message }: AuthFormErrorProps) {
  return message ? <FieldError>{message}</FieldError> : null
}

type AuthSubmitProps = {
  children: ReactNode
  disabled: boolean
}

export function AuthSubmit({ children, disabled }: AuthSubmitProps) {
  return (
    <Button disabled={disabled} size="lg" type="submit">
      {children}
    </Button>
  )
}
