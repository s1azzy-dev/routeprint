import { describe, expect, it } from "vitest"

import {
  buildFlightRouteOverlay,
  type FlightRoute,
} from "@/lib/flight-route-geometry"

function route(
  from: FlightRoute["from"],
  to: FlightRoute["to"],
  count = 1,
): FlightRoute {
  return { id: "first:second", from, to, count }
}

function parts(flight: FlightRoute) {
  const geometry = buildFlightRouteOverlay([flight]).lines.features[0]!.geometry
  return geometry.type === "LineString"
    ? [geometry.coordinates]
    : geometry.coordinates
}

describe("flight route geometry", () => {
  it("keeps endpoints and includes the high point of a transatlantic arc in the camera", () => {
    const flight = route([-73.78, 40.64], [-0.46, 51.47])
    const { bounds, labels } = buildFlightRouteOverlay([flight])
    const [line] = parts(flight)

    expect(line?.at(0)).toEqual(flight.from)
    expect(line?.at(-1)).toEqual(flight.to)
    expect(bounds?.[1][1]).toBeGreaterThan(53)
    expect(labels.features).toEqual([])
  })

  it.each([false, true])(
    "cuts the seam in either direction (reverse: %s)",
    (reverse) => {
      const west: FlightRoute["from"] = [179.8, -17]
      const east: FlightRoute["from"] = [-179.7, -17]
      const flight = reverse ? route(east, west, 4) : route(west, east, 4)
      const [first, second] = parts(flight)
      const { bounds, labels, lines } = buildFlightRouteOverlay([flight])

      expect(first?.at(-1)?.[0]).toBe(reverse ? -180 : 180)
      expect(second?.at(0)?.[0]).toBe(reverse ? 180 : -180)
      expect(first?.at(-1)?.[1]).toBe(second?.at(0)?.[1])
      expect(bounds?.[0][0]).toBeCloseTo(179.8)
      expect(bounds?.[1][0]).toBeCloseTo(180.3)
      expect(lines.features[0]).toMatchObject({
        id: flight.id,
        properties: { count: 4 },
      })
      expect(labels.features).toHaveLength(1)
      expect(labels.features[0]).toMatchObject({
        id: flight.id,
        properties: { count: 4 },
      })
    },
  )

  it("cuts the North Pacific route without any segment spanning the map", () => {
    const lineParts = parts(route([139.78, 35.55], [-122.38, 37.62]))
    expect(lineParts).toHaveLength(2)
    for (const line of lineParts) {
      line.slice(1).forEach(([longitude], index) => {
        expect(Math.abs(longitude - line[index]![0])).toBeLessThan(180)
      })
    }
  })

  it("keeps one part for an endpoint on the seam or a route along it", () => {
    expect(parts(route([180, 20], [-170, 30]))[0]?.[0]).toEqual([-180, 20])
    const along = parts(route([180, 20], [-180, 40]))
    expect(along).toHaveLength(1)
    const [line] = along
    expect(line?.every(([longitude]) => longitude === line[0]?.[0])).toBe(true)
  })

  it.each([1, -1])(
    "leaves a polar gap and puts the count on visible geometry (sign %s)",
    (sign) => {
      const flight = route([-149.99, sign * 65], [11.1, sign * 65], 2)
      const [first, second] = parts(flight)
      const limit = sign * 85.05112877980659
      const { labels } = buildFlightRouteOverlay([flight])
      const anchor = labels.features[0]!.geometry.coordinates

      expect(first?.at(-1)?.[1]).toBeCloseTo(limit)
      expect(second?.at(0)?.[1]).toBeCloseTo(limit)
      expect(Math.abs(first!.at(-2)![1])).toBeLessThan(Math.abs(limit))
      expect(Math.abs(second![1]![1])).toBeLessThan(Math.abs(limit))
      expect(Math.abs(anchor[1])).toBeLessThan(Math.abs(limit))
      expect([...first!, ...second!]).toContainEqual(anchor)
    },
  )

  it("finds a short polar excursion between angular samples", () => {
    const flight = route([-9, 85.001], [9, 85.001])
    expect(parts(flight)).toHaveLength(2)
  })

  it("keeps a near-antipodal arc and omits invalid, ambiguous and invisible pairs", () => {
    const nearAntipodes = route([10, 20], [-170.00001, -20])
    expect(parts(nearAntipodes).flat().length).toBeGreaterThan(30)
    for (const flight of [
      route([10, 20], [-170, -20]),
      route([180, 20], [-180, 20]),
      route([0, 90], [90, 90]),
      route([0, 86], [10, 87]),
      route([181, 0], [10, 0]),
      route([NaN, 0], [10, 0]),
      route([null as unknown as number, 0], [10, 0]),
    ]) {
      expect(buildFlightRouteOverlay([flight])).toEqual({
        lines: { type: "FeatureCollection", features: [] },
        labels: { type: "FeatureCollection", features: [] },
        bounds: undefined,
      })
    }
  })

  it("preserves overlapping route identities and their separate counts", () => {
    const first = route([0, 10], [0, 20], 2)
    const second = { ...route([0, 15], [0, 25], 5), id: "third:fourth" }
    const { lines, labels } = buildFlightRouteOverlay([first, second])

    expect(lines.features.map(({ id }) => id)).toEqual([first.id, second.id])
    expect(labels.features.map(({ properties }) => properties.count)).toEqual([
      2, 5,
    ])
  })
})
