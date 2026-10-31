import { Badge } from "@/components/ui/badge"
import type { FlightCopy, FlightRow } from "./types"

export default function FlightSummary({
  flight,
  copy,
}: {
  flight: FlightRow
  copy: FlightCopy
}) {
  return (
    <div className="flex min-w-0 flex-col gap-2">
      <p className="text-lg font-semibold">
        {flight.departureAirport.name} → {flight.arrivalAirport.name}
      </p>
      <p>
        {flight.departureDate}
        {flight.departureTime ? ` · ${flight.departureTime}` : ""}
      </p>
      {flight.arrivalDate ? (
        <p className="text-sm text-muted-foreground">
          {copy.fields.arrival_date}: {flight.arrivalDate}
          {flight.arrivalTime ? ` · ${flight.arrivalTime}` : ""}
        </p>
      ) : null}
      <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
        <span>{flight.marketingAirline?.name || copy.unknown}</span>
        {flight.marketingAirline?.pending ? (
          <Badge variant="secondary">{copy.airline_pending}</Badge>
        ) : null}
        {flight.flightNumber ? <span>{flight.flightNumber}</span> : null}
      </div>
    </div>
  )
}
