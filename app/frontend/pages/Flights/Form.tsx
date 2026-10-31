import { Head, Link, useForm } from "@inertiajs/react"
import { useState, type FormEvent } from "react"
import AirlinePicker from "@/components/routeprint/airline-picker"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import AirportPicker from "./airport-picker"
import type { FlightFormProps, FlightValues } from "./types"

export default function Form(props: FlightFormProps) {
  const {
    copy,
    values,
    selected,
    urls,
    editing,
    duplicates,
    formErrors,
    airlinePicker,
  } = props
  const form = useForm({ flight: { ...values, confirmed_duplicate: false } })
  const [choices, setChoices] = useState(selected)
  const title = editing ? copy.edit_title : copy.new_title
  const data = form.data.flight
  const sameRoute = (
    ["departure_place_id", "arrival_place_id", "departure_date"] as const
  ).every((key) => data[key] === values[key])
  const hasDuplicates = duplicates.length > 0 && sameRoute
  function change(key: keyof FlightValues, value: string) {
    form.setData("flight", {
      ...data,
      [key]: value,
      confirmed_duplicate: false,
    })
  }
  function save(confirmed: boolean) {
    form.transform((current) => ({
      flight: { ...current.flight, confirmed_duplicate: confirmed },
    }))
    if (editing) form.patch(urls.submit)
    else form.post(urls.submit)
  }
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (event.target === event.currentTarget) save(false)
  }
  function error(key: string) {
    return (
      formErrors[key] ||
      form.errors[`flight.${key}` as keyof typeof form.errors]
    )
  }
  function scheduleField(
    key:
      | "departure_date"
      | "arrival_date"
      | "departure_time"
      | "arrival_time"
      | "flight_number",
  ) {
    return (
      <Field key={key} data-invalid={Boolean(error(key)) || undefined}>
        <FieldLabel htmlFor={key}>{copy.fields[key]}</FieldLabel>
        <Input
          id={key}
          type={
            key.includes("date")
              ? "date"
              : key.includes("time")
                ? "time"
                : "text"
          }
          required={key === "departure_date"}
          maxLength={key === "flight_number" ? 16 : undefined}
          aria-invalid={Boolean(error(key))}
          aria-describedby={error(key) ? key + "-error" : undefined}
          value={data[key]}
          onChange={(event) => change(key, event.target.value)}
        />
        <FieldError id={key + "-error"}>{error(key)}</FieldError>
      </Field>
    )
  }
  function carrierField(role: "marketing" | "operating") {
    const key = `${role}_airline_id` as const
    return (
      <Field data-invalid={Boolean(error(key)) || undefined}>
        <FieldLabel htmlFor={key}>{copy.fields[key]}</FieldLabel>
        <AirlinePicker
          triggerId={key}
          copy={airlinePicker.copy}
          countries={airlinePicker.countries}
          flightDate={data.departure_date}
          searchUrl={urls.airlineSearch}
          submitUrl={urls.airlineSubmit}
          value={choices[role]}
          onChange={(airline) => {
            setChoices((current) => ({ ...current, [role]: airline }))
            change(key, airline.id)
          }}
        />
        {choices[role] ? (
          <Button
            type="button"
            variant="ghost"
            className="w-fit"
            onClick={() => {
              setChoices((current) => ({ ...current, [role]: null }))
              change(key, "")
            }}
          >
            {copy.clear}
          </Button>
        ) : (
          <FieldDescription>{copy.unknown}</FieldDescription>
        )}
        <FieldError>{error(key)}</FieldError>
      </Field>
    )
  }

  return (
    <main className="mx-auto w-full max-w-3xl px-4 py-8 sm:py-12">
      <Head title={title} />
      <Button asChild variant="ghost" className="mb-4">
        <Link href={urls.index}>{copy.back}</Link>
      </Button>
      <Card>
        <CardHeader>
          <CardTitle>
            <h1 className="text-2xl">{title}</h1>
          </CardTitle>
          <CardDescription>{copy.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={submit} className="flex flex-col gap-6">
            <FieldGroup className="grid gap-5 sm:grid-cols-2">
              {(["departure", "arrival"] as const).map((role) => {
                const key = `${role}_place_id` as const
                return (
                  <Field
                    key={role}
                    data-invalid={Boolean(error(key)) || undefined}
                  >
                    <FieldLabel htmlFor={key}>{copy.fields[key]}</FieldLabel>
                    <AirportPicker
                      id={key}
                      value={choices[role]}
                      copy={copy}
                      searchUrl={urls.airportSearch}
                      invalid={Boolean(error(key))}
                      onChange={(airport) => {
                        setChoices((current) => ({
                          ...current,
                          [role]: airport,
                        }))
                        change(key, airport.id)
                      }}
                    />
                    <FieldError>{error(key)}</FieldError>
                  </Field>
                )
              })}
              {scheduleField("departure_date")}
              {scheduleField("departure_time")}
              {scheduleField("arrival_date")}
              {scheduleField("arrival_time")}
            </FieldGroup>
            <p className="text-sm text-muted-foreground">{copy.local_time}</p>
            <FieldGroup className="grid gap-5 sm:grid-cols-2">
              {carrierField("marketing")}
              {scheduleField("flight_number")}
            </FieldGroup>
            <details>
              <summary className="cursor-pointer rounded-md py-2 font-medium focus-visible:outline-2">
                {copy.additional}
              </summary>
              <FieldGroup className="pt-4">
                {carrierField("operating")}
              </FieldGroup>
            </details>
            {error("base") ? <FieldError>{error("base")}</FieldError> : null}
            {hasDuplicates ? (
              <Alert>
                <AlertTitle>{copy.duplicate}</AlertTitle>
                <AlertDescription>
                  <ul>
                    {duplicates.map((flight) => (
                      <li key={flight.id}>
                        <Link href={flight.urls.show}>
                          {flight.departureDate} ·{" "}
                          {flight.departureAirport.name} →{" "}
                          {flight.arrivalAirport.name}
                        </Link>
                      </li>
                    ))}
                  </ul>
                  <Button
                    type="button"
                    className="mt-3"
                    disabled={form.processing}
                    onClick={() => save(true)}
                  >
                    {copy.confirm_duplicate}
                  </Button>
                </AlertDescription>
              </Alert>
            ) : null}
            <div className="flex flex-wrap gap-3">
              {!hasDuplicates ? (
                <Button type="submit" disabled={form.processing}>
                  {form.processing ? copy.saving : copy.save}
                </Button>
              ) : null}
              <Button asChild variant="outline">
                <Link href={urls.index}>{copy.cancel}</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </main>
  )
}
