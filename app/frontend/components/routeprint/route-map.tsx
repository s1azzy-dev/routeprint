import { useEffect, useRef } from "react"
import maplibregl from "maplibre-gl"
import "maplibre-gl/dist/maplibre-gl.css"

const DEFAULT_MAP_STYLE_URL = "https://tiles.openfreemap.org/styles/liberty"
const INITIAL_VIEW = {
  center: [15, 20] as [number, number],
  zoom: 2,
}

export function RouteMap() {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!containerRef.current) {
      return
    }

    const map = new maplibregl.Map({
      attributionControl: false,
      center: INITIAL_VIEW.center,
      container: containerRef.current,
      style: DEFAULT_MAP_STYLE_URL,
      zoom: INITIAL_VIEW.zoom,
    })

    map.addControl(new maplibregl.NavigationControl(), "top-right")
    map.addControl(
      new maplibregl.AttributionControl({ compact: true }),
      "bottom-right",
    )
    map.on("style.load", () => map.resize())

    return () => {
      map.remove()
    }
  }, [])

  return (
    <div className="relative h-full min-h-full w-full">
      <div
        ref={containerRef}
        aria-label="Route map"
        className="absolute inset-0 h-full min-h-full w-full"
        data-testid="route-map"
      />
    </div>
  )
}
