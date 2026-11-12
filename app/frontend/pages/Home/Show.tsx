import { RouteMap } from "@/components/routeprint/route-map"
import type { FlightRoute } from "@/lib/flight-route-geometry"

export default function HomeShow({
  flightRoutes,
}: {
  flightRoutes: FlightRoute[]
}) {
  return (
    <main className="relative h-[calc(100dvh-3.5rem)] min-h-[480px] w-full overflow-hidden bg-background text-foreground">
      <RouteMap routes={flightRoutes} />
    </main>
  )
}
