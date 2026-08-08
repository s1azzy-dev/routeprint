import { useState, type FormEvent } from "react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import {
  Command,
  CommandGroup,
  CommandItem,
  CommandList,
} from "@/components/ui/command"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Spinner } from "@/components/ui/spinner"

export type AirlineChoice = {
  countryName: string | null
  id: string
  inactive: boolean
  name: string
  pending: boolean
  preferredCode: string | null
}

export type AirlinePickerCopy = {
  addAction: string
  addDescription: string
  addTitle: string
  cancel: string
  confirmation: string
  createAction: string
  creating: string
  dialogDescription: string
  dialogTitle: string
  fields: {
    code: { description: string; label: string }
    country: { label: string; none: string }
    name: { label: string }
  }
  inactive: string
  noResults: string
  pending: string
  searchAction: string
  searchError: string
  searchLabel: string
  searchPlaceholder: string
  searching: string
  submitError: string
  triggerPlaceholder: string
  validation: {
    code: string
    confirmation: string
    country: string
    name: string
  }
}

type CountryOption = { id: string; name: string }

type AirlinePickerProps = {
  copy: AirlinePickerCopy
  countries: CountryOption[]
  flightDate?: string
  onChange: (airline: AirlineChoice) => void
  searchUrl: string
  submitUrl: string
  value: AirlineChoice | null
}

type Mode = "search" | "add"

export default function AirlinePicker({
  copy,
  countries,
  flightDate,
  onChange,
  searchUrl,
  submitUrl,
  value,
}: AirlinePickerProps) {
  const [open, setOpen] = useState(false)
  const [mode, setMode] = useState<Mode>("search")
  const [query, setQuery] = useState("")
  const [results, setResults] = useState<AirlineChoice[]>([])
  const [searched, setSearched] = useState(false)
  const [searching, setSearching] = useState(false)
  const [searchFailed, setSearchFailed] = useState(false)
  const [name, setName] = useState("")
  const [code, setCode] = useState("")
  const [countryId, setCountryId] = useState("")
  const [confirmed, setConfirmed] = useState(false)
  const [creating, setCreating] = useState(false)
  const [submissionErrorFields, setSubmissionErrorFields] = useState<string[]>(
    [],
  )

  async function handleSearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setSearching(true)
    setSearchFailed(false)

    try {
      const url = new URL(searchUrl, window.location.origin)
      url.searchParams.set("query", query.trim())
      if (flightDate) url.searchParams.set("flight_date", flightDate)
      const response = await fetch(`${url.pathname}${url.search}`, {
        headers: { Accept: "application/json" },
      })
      const body = (await response.json()) as { airlines?: AirlineChoice[] }
      if (!response.ok || !body.airlines) throw new Error("search_failed")

      setResults(body.airlines)
      setSearched(true)
    } catch {
      setSearchFailed(true)
    } finally {
      setSearching(false)
    }
  }

  function startSubmission() {
    setName(query.trim())
    setCode("")
    setCountryId("")
    setConfirmed(false)
    setSubmissionErrorFields([])
    setMode("add")
  }

  async function handleSubmission(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setCreating(true)
    setSubmissionErrorFields([])

    try {
      const response = await fetch(submitUrl, {
        body: JSON.stringify({
          airline: {
            code: code.trim() || null,
            confirmed,
            country_id: countryId || null,
            name: name.trim(),
          },
        }),
        headers: jsonHeaders(),
        method: "POST",
      })
      const body = (await response.json()) as {
        airline?: AirlineChoice
        errors?: Record<string, string[]>
      }
      if (!response.ok || !body.airline) {
        setSubmissionErrorFields(Object.keys(body.errors ?? { base: [] }))
        return
      }

      selectAirline(body.airline)
    } catch {
      setSubmissionErrorFields(["base"])
    } finally {
      setCreating(false)
    }
  }

  function selectAirline(airline: AirlineChoice) {
    onChange(airline)
    setMode("search")
    setOpen(false)
  }

  function handleOpenChange(nextOpen: boolean) {
    setOpen(nextOpen)
    if (!nextOpen) setMode("search")
  }

  function submissionHasError(field: string) {
    return submissionErrorFields.includes(field)
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Button type="button" variant="outline">
          {value ? choiceLabel(value) : copy.triggerPlaceholder}
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {mode === "search" ? copy.dialogTitle : copy.addTitle}
          </DialogTitle>
          <DialogDescription>
            {mode === "search" ? copy.dialogDescription : copy.addDescription}
          </DialogDescription>
        </DialogHeader>

        {mode === "search" ? (
          <SearchPanel
            copy={copy}
            onSearch={handleSearch}
            onSelect={selectAirline}
            onStartSubmission={startSubmission}
            query={query}
            results={results}
            searched={searched}
            searching={searching}
            searchFailed={searchFailed}
            setQuery={setQuery}
          />
        ) : (
          <form
            onSubmit={(event) => {
              void handleSubmission(event)
            }}
          >
            <FieldGroup>
              <Field data-invalid={submissionHasError("name")}>
                <FieldLabel htmlFor="airline-name">
                  {copy.fields.name.label}
                </FieldLabel>
                <Input
                  aria-invalid={submissionHasError("name")}
                  id="airline-name"
                  maxLength={160}
                  onChange={(event) => setName(event.target.value)}
                  value={name}
                />
                {submissionHasError("name") ? (
                  <FieldError>{copy.validation.name}</FieldError>
                ) : null}
              </Field>

              <Field data-invalid={submissionHasError("code")}>
                <FieldLabel htmlFor="airline-code">
                  {copy.fields.code.label}
                </FieldLabel>
                <Input
                  aria-invalid={submissionHasError("code")}
                  id="airline-code"
                  maxLength={3}
                  onChange={(event) => setCode(event.target.value)}
                  value={code}
                />
                <FieldDescription>
                  {copy.fields.code.description}
                </FieldDescription>
                {submissionHasError("code") ? (
                  <FieldError>{copy.validation.code}</FieldError>
                ) : null}
              </Field>

              <Field data-invalid={submissionHasError("country_id")}>
                <FieldLabel htmlFor="airline-country">
                  {copy.fields.country.label}
                </FieldLabel>
                <Select
                  onValueChange={(nextValue) =>
                    setCountryId(nextValue === "none" ? "" : nextValue)
                  }
                  value={countryId || "none"}
                >
                  <SelectTrigger
                    aria-invalid={submissionHasError("country_id")}
                    className="w-full"
                    id="airline-country"
                  >
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectGroup>
                      <SelectItem value="none">
                        {copy.fields.country.none}
                      </SelectItem>
                      {countries.map((country) => (
                        <SelectItem key={country.id} value={country.id}>
                          {country.name}
                        </SelectItem>
                      ))}
                    </SelectGroup>
                  </SelectContent>
                </Select>
                {submissionHasError("country_id") ? (
                  <FieldError>{copy.validation.country}</FieldError>
                ) : null}
              </Field>

              <Field
                data-invalid={submissionHasError("confirmed")}
                orientation="horizontal"
              >
                <Checkbox
                  aria-invalid={submissionHasError("confirmed")}
                  checked={confirmed}
                  id="airline-confirmation"
                  onCheckedChange={(checked) => setConfirmed(checked === true)}
                />
                <FieldLabel htmlFor="airline-confirmation">
                  {copy.confirmation}
                </FieldLabel>
                {submissionHasError("confirmed") ? (
                  <FieldError>{copy.validation.confirmation}</FieldError>
                ) : null}
              </Field>

              {submissionHasError("base") ? (
                <FieldError>{copy.submitError}</FieldError>
              ) : null}
            </FieldGroup>

            <DialogFooter className="mt-5">
              <Button
                type="button"
                variant="outline"
                onClick={() => setMode("search")}
              >
                {copy.cancel}
              </Button>
              <Button disabled={creating || !confirmed} type="submit">
                {creating ? <Spinner data-icon="inline-start" /> : null}
                {creating ? copy.creating : copy.createAction}
              </Button>
            </DialogFooter>
          </form>
        )}
      </DialogContent>
    </Dialog>
  )
}

type SearchPanelProps = {
  copy: AirlinePickerCopy
  onSearch: (event: FormEvent<HTMLFormElement>) => Promise<void>
  onSelect: (airline: AirlineChoice) => void
  onStartSubmission: () => void
  query: string
  results: AirlineChoice[]
  searched: boolean
  searching: boolean
  searchFailed: boolean
  setQuery: (query: string) => void
}

function SearchPanel({
  copy,
  onSearch,
  onSelect,
  onStartSubmission,
  query,
  results,
  searched,
  searching,
  searchFailed,
  setQuery,
}: SearchPanelProps) {
  return (
    <div className="flex flex-col gap-4">
      <form
        onSubmit={(event) => {
          void onSearch(event)
        }}
      >
        <Field data-invalid={searchFailed}>
          <FieldLabel htmlFor="airline-search">{copy.searchLabel}</FieldLabel>
          <InputGroup>
            <InputGroupInput
              aria-invalid={searchFailed}
              id="airline-search"
              onChange={(event) => setQuery(event.target.value)}
              placeholder={copy.searchPlaceholder}
              value={query}
            />
            <InputGroupAddon align="inline-end">
              <InputGroupButton
                disabled={searching || query.trim() === ""}
                type="submit"
              >
                {searching ? <Spinner data-icon="inline-start" /> : null}
                {searching ? copy.searching : copy.searchAction}
              </InputGroupButton>
            </InputGroupAddon>
          </InputGroup>
          {searchFailed ? <FieldError>{copy.searchError}</FieldError> : null}
        </Field>
      </form>

      {results.length > 0 ? (
        <Command shouldFilter={false}>
          <CommandList>
            <CommandGroup>
              {results.map((airline) => (
                <CommandItem
                  key={airline.id}
                  onSelect={() => onSelect(airline)}
                  value={airline.id}
                >
                  <span className="flex min-w-0 flex-1 flex-col gap-0.5">
                    <span className="truncate font-medium">{airline.name}</span>
                    <span className="truncate text-xs text-muted-foreground">
                      {choiceDetails(airline)}
                    </span>
                  </span>
                  {airline.pending ? (
                    <Badge variant="secondary">{copy.pending}</Badge>
                  ) : null}
                  {airline.inactive ? (
                    <Badge variant="outline">{copy.inactive}</Badge>
                  ) : null}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      ) : null}

      {searched && results.length === 0 ? (
        <Empty>
          <EmptyHeader>
            <EmptyTitle>{copy.noResults}</EmptyTitle>
            <EmptyDescription>{copy.addDescription}</EmptyDescription>
          </EmptyHeader>
          <EmptyContent>
            <Button type="button" onClick={onStartSubmission}>
              {copy.addAction}
            </Button>
          </EmptyContent>
        </Empty>
      ) : null}
    </div>
  )
}

function choiceLabel(airline: AirlineChoice) {
  return airline.preferredCode
    ? `${airline.name} · ${airline.preferredCode}`
    : airline.name
}

function choiceDetails(airline: AirlineChoice) {
  return [airline.preferredCode, airline.countryName]
    .filter(Boolean)
    .join(" · ")
}

function jsonHeaders() {
  const csrfToken = document.querySelector<HTMLMetaElement>(
    'meta[name="csrf-token"]',
  )?.content
  return {
    Accept: "application/json",
    "Content-Type": "application/json",
    ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
  }
}
