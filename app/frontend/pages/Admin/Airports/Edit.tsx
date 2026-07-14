import { useForm } from "@inertiajs/react"
import type { FormEvent } from "react"

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
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

import AdminLayout, { type AdminNavigationSection } from "../AdminLayout"

type AirportForm = {
  airport: {
    country_code: string
    icao_code: string
    iata_code: string
    municipality_name: string
    name: string
    operational_status: string
    region_code: string
    time_zone: string
  }
}

interface Option {
  label: string
  value: string
}

export interface AdminAirportsEditPageProps {
  airport: {
    countryCode: string
    icaoCode: string | null
    iataCode: string | null
    municipalityName: string | null
    name: string
    operationalStatus: string
    placeId: string
    regionCode: string | null
    timeZone: string | null
  }
  copy: {
    back: string
    description: string
    fields: Record<
      keyof AirportForm["airport"],
      { label: string; placeholder: string }
    >
    formHeading: string
    heading: string
    submit: string
    title: string
    toolbarLabel: string
  }
  formErrors: Record<string, string>
  navigation: { sections: AdminNavigationSection[] }
  options: { operationalStatuses: Option[] }
  urls: { index: string; update: string }
}

export default function Edit({
  airport,
  copy,
  formErrors,
  navigation,
  options,
  urls,
}: AdminAirportsEditPageProps) {
  const { data, errors, patch, processing, setData } = useForm<AirportForm>({
    airport: {
      country_code: airport.countryCode,
      icao_code: airport.icaoCode ?? "",
      iata_code: airport.iataCode ?? "",
      municipality_name: airport.municipalityName ?? "",
      name: airport.name,
      operational_status: airport.operationalStatus,
      region_code: airport.regionCode ?? "",
      time_zone: airport.timeZone ?? "",
    },
  })

  function updateField(field: keyof AirportForm["airport"], value: string) {
    setData("airport", { ...data.airport, [field]: value })
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    patch(urls.update)
  }

  const fieldError = (field: keyof AirportForm["airport"]) =>
    formErrors[field] ?? errors[`airport.${field}`]

  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      <Button asChild className="w-fit" variant="ghost">
        <a href={urls.index}>{copy.back}</a>
      </Button>

      <Card className="max-w-4xl">
        <CardHeader>
          <CardTitle>{copy.formHeading}</CardTitle>
          <CardDescription>{copy.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="flex flex-col gap-6" onSubmit={submit}>
            <FieldGroup className="grid gap-5 md:grid-cols-2">
              {(
                Object.keys(data.airport) as Array<keyof AirportForm["airport"]>
              ).map((field) => (
                <Field
                  data-invalid={fieldError(field) ? "true" : undefined}
                  key={field}
                >
                  <FieldLabel htmlFor={`admin-airport-${field}`}>
                    {copy.fields[field].label}
                  </FieldLabel>
                  {field === "operational_status" ? (
                    <Select
                      value={data.airport[field]}
                      onValueChange={(value) => updateField(field, value)}
                    >
                      <SelectTrigger
                        aria-invalid={fieldError(field) ? true : undefined}
                        id={`admin-airport-${field}`}
                      >
                        <SelectValue
                          placeholder={copy.fields[field].placeholder}
                        />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectGroup>
                          {options.operationalStatuses.map((option) => (
                            <SelectItem key={option.value} value={option.value}>
                              {option.label}
                            </SelectItem>
                          ))}
                        </SelectGroup>
                      </SelectContent>
                    </Select>
                  ) : (
                    <Input
                      aria-invalid={fieldError(field) ? true : undefined}
                      id={`admin-airport-${field}`}
                      onChange={(event) =>
                        updateField(field, event.currentTarget.value)
                      }
                      placeholder={copy.fields[field].placeholder}
                      value={data.airport[field]}
                    />
                  )}
                  <FieldError>{fieldError(field)}</FieldError>
                </Field>
              ))}
            </FieldGroup>

            <Button className="w-fit" disabled={processing} type="submit">
              {copy.submit}
            </Button>
          </form>
        </CardContent>
      </Card>
    </AdminLayout>
  )
}
