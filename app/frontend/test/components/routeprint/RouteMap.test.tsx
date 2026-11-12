import { render, screen } from "@testing-library/react"
import type { GeoJSONSourceSpecification } from "maplibre-gl"
import { afterEach, describe, expect, it, vi } from "vitest"

const {
  eventHandlers,
  attributionControlConstructor,
  mapConstructor,
  mapInstance,
  source,
  navigationControlConstructor,
  setWorkerUrl,
} = vi.hoisted(() => {
  const eventHandlers = new globalThis.Map<string, () => void>()
  const source = { setData: vi.fn() }
  const mapInstance = {
    addControl: vi.fn(),
    addLayer: vi.fn(),
    addSource:
      vi.fn<(id: string, options: GeoJSONSourceSpecification) => void>(),
    fitBounds: vi.fn<(bounds: [[number, number], [number, number]]) => void>(),
    getSource: vi.fn(),
    on: vi.fn((event: string, handler: () => void) => {
      eventHandlers.set(event, handler)
    }),
    remove: vi.fn(),
    resize: vi.fn(),
  }

  return {
    attributionControlConstructor: vi.fn(function AttributionControl() {}),
    eventHandlers,
    mapConstructor: vi.fn(function Map() {
      return mapInstance
    }),
    mapInstance,
    navigationControlConstructor: vi.fn(function NavigationControl() {}),
    setWorkerUrl: vi.fn(),
    source,
  }
})

vi.mock("maplibre-gl", () => ({
  AttributionControl: attributionControlConstructor,
  Map: mapConstructor,
  NavigationControl: navigationControlConstructor,
  setWorkerUrl,
}))

import { RouteMap } from "../../../components/routeprint/route-map"
import type { FlightRoute } from "@/lib/flight-route-geometry"

const route: FlightRoute = {
  id: "first:second",
  from: [179.8, -17],
  to: [-179.7, -17],
  count: 2,
}

describe("RouteMap", () => {
  afterEach(() => {
    eventHandlers.clear()
    mapInstance.getSource.mockReset()
    vi.clearAllMocks()
  })

  it("initializes MapLibre with the shared vector basemap", () => {
    render(<RouteMap routes={[]} />)

    expect(screen.getByTestId("route-map")).toBeVisible()
    expect(mapConstructor).toHaveBeenCalledWith(
      expect.objectContaining({
        attributionControl: false,
        style: "https://tiles.openfreemap.org/styles/liberty",
      }),
    )
    expect(attributionControlConstructor).toHaveBeenCalledWith({
      compact: true,
    })
    expect(navigationControlConstructor).toHaveBeenCalledOnce()
    expect(setWorkerUrl).toHaveBeenCalledWith(
      expect.stringContaining("maplibre-gl-worker"),
    )

    eventHandlers.get("style.load")?.()

    expect(mapInstance.resize).toHaveBeenCalledOnce()
  })

  it("removes the map on unmount", () => {
    const { unmount } = render(<RouteMap routes={[]} />)

    unmount()

    expect(mapInstance.remove).toHaveBeenCalled()
  })

  it("installs shared layers, updates their data, and restores them with fresh data on style reload", () => {
    const { rerender } = render(<RouteMap routes={[route]} />)
    eventHandlers.get("style.load")?.()

    expect(mapInstance.addLayer).toHaveBeenCalledWith(
      expect.objectContaining({ type: "line" }),
    )
    expect(mapInstance.addLayer).toHaveBeenCalledWith(
      expect.objectContaining({ type: "symbol" }),
    )
    expect(mapInstance.addSource.mock.calls[0]?.[1]).toMatchObject({
      promoteId: "routeId",
    })
    expect(mapInstance.fitBounds.mock.calls[0]?.[0][1][0]).toBeCloseTo(180.3)

    mapInstance.getSource.mockReturnValue(source)
    rerender(<RouteMap routes={[{ ...route, count: 3 }]} />)
    const changedLabel = { features: [{ properties: { count: 3 } }] }
    expect(source.setData.mock.lastCall?.[0]).toMatchObject(changedLabel)

    mapInstance.getSource.mockReturnValue(undefined)
    eventHandlers.get("style.load")?.()
    const [name, options] = mapInstance.addSource.mock.lastCall ?? []
    expect(name).toBe("flight-route-counts")
    expect(options).toMatchObject({ data: changedLabel, promoteId: "routeId" })
    expect(mapConstructor).toHaveBeenCalledOnce()
    expect(mapInstance.fitBounds).toHaveBeenCalledOnce()

    mapInstance.getSource.mockReturnValue(source)
    rerender(<RouteMap routes={[]} />)
    expect(source.setData).toHaveBeenLastCalledWith({
      type: "FeatureCollection",
      features: [],
    })
  })
})
