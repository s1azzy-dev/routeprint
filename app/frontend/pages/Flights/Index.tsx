import { Head, Link } from "@inertiajs/react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import FlightSummary from "./flight-summary"
import type { FlightCopy, FlightRow } from "./types"

export default function Index({
  copy,
  flights,
  urls,
  pagination,
}: {
  copy: FlightCopy
  flights: FlightRow[]
  urls: { new: string }
  pagination: { nextUrl: string | null; previousUrl: string | null }
}) {
  return (
    <main className="mx-auto max-w-4xl px-4 py-8 sm:py-12">
      <Head title={copy.title} />
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-3xl font-semibold">{copy.title}</h1>
        <Button asChild>
          <Link href={urls.new}>{copy.add}</Link>
        </Button>
      </div>
      {flights.length ? (
        <Card>
          <CardContent className="divide-y">
            {flights.map((flight) => (
              <Link
                className="block rounded-md py-5 outline-none hover:bg-muted/40 focus-visible:ring-2 focus-visible:ring-ring"
                href={flight.urls.show}
                key={flight.id}
              >
                <FlightSummary flight={flight} copy={copy} />
              </Link>
            ))}
          </CardContent>
        </Card>
      ) : (
        <Empty>
          <EmptyHeader>
            <EmptyTitle>{copy.empty}</EmptyTitle>
            <EmptyDescription>{copy.empty_description}</EmptyDescription>
          </EmptyHeader>
        </Empty>
      )}
      <nav aria-label={copy.title} className="mt-6 flex gap-3">
        {pagination.previousUrl ? (
          <Button asChild variant="outline">
            <Link href={pagination.previousUrl}>{copy.previous}</Link>
          </Button>
        ) : null}
        {pagination.nextUrl ? (
          <Button asChild variant="outline">
            <Link href={pagination.nextUrl}>{copy.next}</Link>
          </Button>
        ) : null}
      </nav>
    </main>
  )
}
