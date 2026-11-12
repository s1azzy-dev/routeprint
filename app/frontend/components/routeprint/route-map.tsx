import { useEffect, useEffectEvent, useMemo, useRef } from "react"
import * as maplibregl from "maplibre-gl"
import mapWorkerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?url"
import "maplibre-gl/dist/maplibre-gl.css"

import {
  buildFlightRouteOverlay,
  OVERVIEW_MAX_ZOOM,
  type FlightRoute,
} from "@/lib/flight-route-geometry"

const DEFAULT_MAP_STYLE_URL = "https://tiles.openfreemap.org/styles/liberty"
const ROUTE_LINES = "flight-routes"
const ROUTE_COUNTS = "flight-route-counts"
const INITIAL_VIEW = {
  center: [15, 20] as [number, number],
  zoom: 2,
}

export function RouteMap({ routes }: { routes: FlightRoute[] }) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<maplibregl.Map>(null)
  const hasFitted = useRef(false)
  const overlay = useMemo(() => buildFlightRouteOverlay(routes), [routes])

  const applyOverlay = useEffectEvent((map: maplibregl.Map) => {
    const { lines, labels, bounds } = overlay
    const lineSource = map.getSource<maplibregl.GeoJSONSource>(ROUTE_LINES)
    const countSource = map.getSource<maplibregl.GeoJSONSource>(ROUTE_COUNTS)
    if (lineSource && countSource) {
      void lineSource.setData(lines)
      void countSource.setData(labels)
    } else {
      // Preserve string route IDs through MapLibre's vector tile conversion.
      map.addSource(ROUTE_LINES, {
        type: "geojson",
        data: lines,
        promoteId: "routeId",
        tolerance: 0,
      })
      map.addLayer({
        id: ROUTE_LINES,
        type: "line",
        source: ROUTE_LINES,
        layout: { "line-cap": "round", "line-join": "round" },
        paint: { "line-color": "#146c5c", "line-width": 2.5 },
      })
      map.addSource(ROUTE_COUNTS, {
        type: "geojson",
        data: labels,
        promoteId: "routeId",
      })
      map.addLayer({
        id: ROUTE_COUNTS,
        type: "symbol",
        source: ROUTE_COUNTS,
        layout: {
          "text-field": ["to-string", ["get", "count"]],
          "text-font": ["Noto Sans Regular"],
          "text-size": 13,
          "text-offset": [0, -0.85],
          "text-overlap": "never",
        },
        paint: {
          "text-color": "#103e36",
          "text-halo-color": "#fff",
          "text-halo-width": 1.5,
        },
      })
    }

    if (!hasFitted.current && bounds) {
      hasFitted.current = true
      map.fitBounds(bounds, {
        duration: 0,
        maxZoom: OVERVIEW_MAX_ZOOM,
        padding: 40,
      })
    }
  })

  useEffect(() => {
    if (!containerRef.current) {
      return
    }

    maplibregl.setWorkerUrl(mapWorkerUrl)

    const map = new maplibregl.Map({
      attributionControl: false,
      center: INITIAL_VIEW.center,
      container: containerRef.current,
      renderWorldCopies: true,
      style: DEFAULT_MAP_STYLE_URL,
      zoom: INITIAL_VIEW.zoom,
    })
    mapRef.current = map

    map.addControl(new maplibregl.NavigationControl(), "top-right")
    map.addControl(
      new maplibregl.AttributionControl({ compact: true }),
      "bottom-right",
    )
    map.on("style.load", () => {
      map.resize()
      applyOverlay(map)
    })

    return () => {
      mapRef.current = null
      hasFitted.current = false
      map.remove()
    }
  }, [])

  useEffect(() => {
    const map = mapRef.current
    if (map?.getSource(ROUTE_LINES)) applyOverlay(map)
  }, [overlay])

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
