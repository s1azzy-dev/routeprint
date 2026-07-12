import { fireEvent, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

const {
  eventHandlers,
  attributionControlConstructor,
  mapConstructor,
  mapInstance,
  navigationControlConstructor,
} = vi.hoisted(() => {
  const eventHandlers = new globalThis.Map<string, () => void>()
  const mapInstance = {
    addControl: vi.fn(),
    flyTo: vi.fn(),
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
  }
})

vi.mock("maplibre-gl", () => ({
  default: {
    AttributionControl: attributionControlConstructor,
    Map: mapConstructor,
    NavigationControl: navigationControlConstructor,
  },
}))

import { RouteMap } from "../../../components/routeprint/route-map"

describe("RouteMap", () => {
  afterEach(() => {
    eventHandlers.clear()
    vi.clearAllMocks()
  })

  it("initializes MapLibre with the shared vector basemap", () => {
    render(<RouteMap />)

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

    eventHandlers.get("style.load")?.()

    expect(mapInstance.resize).toHaveBeenCalledOnce()
  })

  it("resets the view and removes the map on unmount", () => {
    const { unmount } = render(<RouteMap />)

    fireEvent.click(screen.getByRole("button", { name: "Reset map view" }))

    expect(mapInstance.flyTo).toHaveBeenCalledWith({
      center: [15, 20],
      zoom: 2,
    })

    unmount()

    expect(mapInstance.remove).toHaveBeenCalled()
  })
})
