import { RouteMap } from "@/components/routeprint/route-map"

export default function HomeShow() {
  return (
    <main className="relative h-[calc(100dvh-3.5rem)] min-h-[480px] w-full overflow-hidden bg-background text-foreground">
      <RouteMap />
    </main>
  )
}
