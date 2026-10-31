import { Head, Link, useForm } from "@inertiajs/react"
import { Alert, AlertDescription } from "@/components/ui/alert"
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import FlightSummary from "./flight-summary"
import type { FlightCopy, FlightRow } from "./types"

export default function Show({
  copy,
  flight,
  urls,
}: {
  copy: FlightCopy
  flight: FlightRow
  urls: { index: string }
}) {
  const form = useForm({ confirmed: true })
  return (
    <main className="mx-auto max-w-3xl px-4 py-8 sm:py-12">
      <Head title={copy.title} />
      <Button asChild variant="ghost" className="mb-4">
        <Link href={urls.index}>{copy.back}</Link>
      </Button>
      <h1 className="mb-6 text-2xl font-semibold">
        {flight.departureDate} ·{" "}
        {flight.departureAirport.iataCode || flight.departureAirport.name} →{" "}
        {flight.arrivalAirport.iataCode || flight.arrivalAirport.name}
      </h1>
      <Card>
        <CardContent className="flex flex-col gap-6 py-6">
          <FlightSummary flight={flight} copy={copy} />
          {flight.operatingAirline ? (
            <p>
              {copy.fields.operating_airline_id}: {flight.operatingAirline.name}
            </p>
          ) : null}
          {flight.warnings.map((warning) => (
            <Alert key={warning}>
              <AlertDescription>{warning}</AlertDescription>
            </Alert>
          ))}
          <div className="flex flex-wrap gap-3">
            <Button asChild>
              <Link href={flight.urls.edit}>{copy.edit}</Link>
            </Button>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="outline">{copy.delete}</Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>{copy.delete}</AlertDialogTitle>
                  <AlertDialogDescription>
                    {copy.delete_confirmation}
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel disabled={form.processing}>
                    {copy.cancel}
                  </AlertDialogCancel>
                  <Button
                    variant="destructive"
                    disabled={form.processing}
                    onClick={() => form.delete(flight.urls.destroy)}
                  >
                    {copy.confirm_delete}
                  </Button>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </CardContent>
      </Card>
    </main>
  )
}
