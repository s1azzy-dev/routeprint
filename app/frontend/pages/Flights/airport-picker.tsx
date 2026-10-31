import { useEffect, useRef, useState, type FormEvent } from "react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  Command,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Field, FieldError, FieldTitle } from "@/components/ui/field"
import type { AirportChoice, FlightCopy } from "./types"

export default function AirportPicker({
  id,
  value,
  onChange,
  copy,
  searchUrl,
  invalid,
}: {
  id: string
  value: AirportChoice | null
  onChange: (choice: AirportChoice) => void
  copy: FlightCopy
  searchUrl: string
  invalid?: boolean
}) {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState("")
  const [results, setResults] = useState<AirportChoice[]>([])
  const [searched, setSearched] = useState(false)
  const [busy, setBusy] = useState(false)
  const [failed, setFailed] = useState(false)
  const request = useRef<AbortController | null>(null)
  useEffect(() => () => request.current?.abort(), [])

  function changeOpen(next: boolean) {
    request.current?.abort()
    setBusy(false)
    setOpen(next)
  }

  async function search(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    event.stopPropagation()
    request.current?.abort()
    const controller = new AbortController()
    request.current = controller
    setBusy(true)
    setFailed(false)
    try {
      const url = new URL(searchUrl, window.location.origin)
      url.searchParams.set("query", query.trim())
      const response = await fetch(url.pathname + url.search, {
        headers: { Accept: "application/json" },
        signal: controller.signal,
      })
      const body = (await response.json()) as { airports?: AirportChoice[] }
      if (!response.ok || !body.airports) throw new Error("search")
      if (!controller.signal.aborted) {
        setResults(body.airports)
        setSearched(true)
      }
    } catch {
      if (!controller.signal.aborted) setFailed(true)
    } finally {
      if (!controller.signal.aborted) setBusy(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={changeOpen}>
      <DialogTrigger asChild>
        <Button
          id={id}
          type="button"
          variant="outline"
          aria-invalid={invalid}
          aria-describedby={id + "-selection"}
          className="h-auto min-h-10 w-full justify-start whitespace-normal text-left"
        >
          <span id={id + "-selection"}>
            {value ? airportLabel(value) : copy.choose_airport}
          </span>
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{copy.choose_airport}</DialogTitle>
          <DialogDescription>{copy.search_label}</DialogDescription>
        </DialogHeader>
        <Command
          label={copy.search_label}
          shouldFilter={false}
          className="gap-4"
        >
          <form
            onSubmit={(event) => {
              void search(event)
            }}
            className="flex flex-col gap-4"
          >
            <Field data-invalid={failed || undefined}>
              <FieldTitle>{copy.search_label}</FieldTitle>
              <CommandInput
                onKeyDown={(event) => {
                  if (event.key === "Enter" && results.length === 0) {
                    event.preventDefault()
                    event.stopPropagation()
                    if (!busy && query.trim().length >= 2)
                      event.currentTarget.form?.requestSubmit()
                  }
                }}
                value={query}
                minLength={2}
                maxLength={100}
                aria-invalid={failed}
                onValueChange={(value) => {
                  request.current?.abort()
                  setBusy(false)
                  setQuery(value)
                  setResults([])
                  setSearched(false)
                }}
              />
              {failed ? <FieldError>{copy.search_error}</FieldError> : null}
            </Field>
            <Button type="submit" disabled={busy || query.trim().length < 2}>
              {busy ? copy.searching : copy.search}
            </Button>
          </form>
          <CommandList>
            <CommandGroup>
              {results.map((airport) => (
                <CommandItem
                  key={airport.id}
                  value={airport.id}
                  onSelect={() => {
                    onChange(airport)
                    changeOpen(false)
                  }}
                >
                  <span className="min-w-0 flex-1 whitespace-normal">
                    {airportLabel(airport)}
                  </span>
                  {airport.closed ? (
                    <Badge variant="secondary">{copy.closed}</Badge>
                  ) : null}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
        {searched && !results.length ? (
          <p role="status">{copy.no_results}</p>
        ) : null}
      </DialogContent>
    </Dialog>
  )
}
export function airportLabel(airport: AirportChoice) {
  return [
    airport.name,
    airport.iataCode || airport.icaoCode,
    airport.countryCode,
  ]
    .filter(Boolean)
    .join(" · ")
}
