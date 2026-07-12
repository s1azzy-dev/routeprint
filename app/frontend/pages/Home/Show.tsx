import { RouteMap } from "@/components/routeprint/route-map"

type HomeShowProps = {
  appName: string
}

export default function HomeShow({ appName }: HomeShowProps) {
  return (
    <main className="relative h-dvh min-h-[480px] w-full overflow-hidden bg-background text-foreground">
      <h1 className="absolute left-4 top-4 z-10 rounded-md bg-background/90 px-3 py-2 text-sm font-semibold shadow-sm backdrop-blur">
        {appName}
      </h1>
      <RouteMap />
    </main>
  )
}
