import type {
  FeatureCollection,
  LineString,
  MultiLineString,
  Point,
} from "geojson"

type Coordinates = [longitude: number, latitude: number]
type Vector = [x: number, y: number, z: number]
type Bounds = [southwest: Coordinates, northeast: Coordinates]
type RouteProperties = { routeId: string; count: number }
type RouteLine = Omit<LineString, "coordinates"> & {
  coordinates: Coordinates[]
}
type RouteMultiLine = Omit<MultiLineString, "coordinates"> & {
  coordinates: Coordinates[][]
}
type RoutePoint = Omit<Point, "coordinates"> & { coordinates: Coordinates }

export type FlightRoute = {
  id: string
  from: Coordinates
  to: Coordinates
  count: number
}

const RADIANS = Math.PI / 180
const MERCATOR_LIMIT = Math.atan(Math.sinh(Math.PI)) / RADIANS
const MERCATOR_LIMIT_Z = Math.sin(MERCATOR_LIMIT * RADIANS)
const EPSILON = 64 * Number.EPSILON
const MAX_STEP = 4 * RADIANS
const MAX_VERTICES = 512
export const OVERVIEW_MAX_ZOOM = 5
const PROJECTED_ERROR = 0.5 / (512 * 2 ** OVERVIEW_MAX_ZOOM)

function isValid([longitude, latitude]: Coordinates) {
  return (
    Number.isFinite(longitude) &&
    Number.isFinite(latitude) &&
    Math.abs(longitude) <= 180 &&
    Math.abs(latitude) <= 90
  )
}

function unitVector([longitude, latitude]: Coordinates): Vector {
  const cosLatitude = Math.cos(latitude * RADIANS)
  return [
    cosLatitude * Math.cos(longitude * RADIANS),
    cosLatitude * Math.sin(longitude * RADIANS),
    Math.sin(latitude * RADIANS),
  ]
}

function cross([ax, ay, az]: Vector, [bx, by, bz]: Vector): Vector {
  return [ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx]
}

function shortestArc(from: Coordinates, to: Coordinates) {
  if (!isValid(from) || !isValid(to)) return

  const a = unitVector(from)
  const b = unitVector(to)
  const normal = cross(a, b)
  const length = Math.hypot(...normal)
  if (length <= EPSILON) return

  const angle = Math.atan2(length, a[0] * b[0] + a[1] * b[1] + a[2] * b[2])
  const u = cross(
    [normal[0] / length, normal[1] / length, normal[2] / length],
    a,
  )

  function at(theta: number): Vector {
    const cos = Math.cos(theta)
    const sin = Math.sin(theta)
    return [
      a[0] * cos + u[0] * sin,
      a[1] * cos + u[1] * sin,
      a[2] * cos + u[2] * sin,
    ]
  }

  return { a, u, angle, at }
}

// Roots of a cos(theta) + b sin(theta) = level, inside the shorter arc.
function crossings(a: number, b: number, level: number, angle: number) {
  const amplitude = Math.hypot(a, b)
  if (amplitude <= EPSILON || Math.abs(level) >= amplitude) return []

  const phase = Math.atan2(b, a)
  const offset = Math.acos(level / amplitude)
  return [phase - offset, phase + offset]
    .map((root) => (root + 2 * Math.PI) % (2 * Math.PI))
    .filter((root) => root > EPSILON && root < angle - EPSILON)
}

function project([longitude, latitude]: Coordinates): Coordinates {
  return [
    longitude / 360,
    Math.asinh(Math.tan(latitude * RADIANS)) / (2 * Math.PI),
  ]
}

function chordError(start: Coordinates, end: Coordinates, point: Coordinates) {
  const [ax, ay] = project(start)
  const [bx, by] = project(end)
  const [px, py] = project(point)
  const dx = bx - ax
  const dy = by - ay
  const length = Math.hypot(dx, dy)
  return length === 0 ? 0 : Math.abs(dx * (py - ay) - dy * (px - ax)) / length
}

function visibleArc(from: Coordinates, to: Coordinates) {
  const arc = shortestArc(from, to)
  if (!arc) return []

  const { a, u, angle, at } = arc
  const breaks = [
    0,
    ...crossings(a[2], u[2], MERCATOR_LIMIT_Z, angle),
    ...crossings(a[2], u[2], -MERCATOR_LIMIT_Z, angle),
    ...crossings(a[1], u[1], 0, angle).filter((theta) => at(theta)[0] < 0),
    angle,
  ].sort((left, right) => left - right)
  const extrema = crossings(u[2], -a[2], 0, angle)

  const spans = breaks.slice(1).flatMap((end, index) => {
    const start = breaks[index]!
    const center = (start + end) / 2
    const midpoint = at(center)
    if (
      end - start <= EPSILON ||
      Math.abs(midpoint[2]) > MERCATOR_LIMIT_Z + EPSILON
    ) {
      return []
    }

    const seam = midpoint[1] < 0 ? -180 : 180
    function position(theta: number): Coordinates {
      const [x, y, z] = at(theta)
      const endpoint = theta === 0 ? from : theta === angle ? to : undefined
      const longitude = endpoint?.[0] ?? Math.atan2(y, x) / RADIANS
      const latitude =
        endpoint?.[1] ?? Math.atan2(z, Math.hypot(x, y)) / RADIANS
      return [
        Math.abs(longitude) >= 180 - EPSILON / RADIANS ? seam : longitude,
        Math.max(-MERCATOR_LIMIT, Math.min(MERCATOR_LIMIT, latitude)),
      ]
    }

    const knots = [
      start,
      ...extrema.filter(
        (theta) =>
          theta > start && theta < end && Math.abs(theta - center) > EPSILON,
      ),
      center,
      end,
    ].sort((left, right) => left - right)
    const stops = [start]
    let previous = start
    for (const knot of knots.slice(1)) {
      const steps = Math.ceil((knot - previous) / MAX_STEP)
      for (let step = 1; step < steps; step++) {
        stops.push(previous + ((knot - previous) * step) / steps)
      }
      stops.push(knot)
      previous = knot
    }
    return [{ start, end, position, stops }]
  })

  // Reserve the required boundary and angular samples before refining chords.
  let budget =
    MAX_VERTICES - spans.reduce((sum, span) => sum + span.stops.length, 0)
  return spans.map(({ start, end, position, stops }) => {
    const coordinates = [position(start)]
    function sample(
      left: number,
      right: number,
      first: Coordinates,
      last: Coordinates,
    ) {
      const half = (left + right) / 2
      const middle = position(half)
      if (
        budget > 0 &&
        right - left > EPSILON &&
        Math.max(
          chordError(first, last, position((left + half) / 2)),
          chordError(first, last, middle),
          chordError(first, last, position((half + right) / 2)),
        ) > PROJECTED_ERROR
      ) {
        budget--
        sample(left, half, first, middle)
        sample(half, right, middle, last)
      } else {
        coordinates.push(last)
      }
    }

    let previous = start
    for (const stop of stops.slice(1)) {
      sample(
        previous,
        stop,
        coordinates[coordinates.length - 1]!,
        position(stop),
      )
      previous = stop
    }
    return {
      coordinates,
      length: end - start,
      anchor: position((start + end) / 2),
    }
  })
}

function wrappedBounds(
  intervals: [number, number][],
  south: number,
  north: number,
): Bounds | undefined {
  // Fit the complement of the largest gap in the union of longitude intervals.
  intervals.sort(([left], [right]) => left - right)
  const [head, ...tail] = intervals
  if (!head) return

  const [first, firstEnd] = head
  let end = firstEnd
  let gap = 0
  let west = -180
  for (const [start, stop] of tail) {
    if (start - end > gap) {
      gap = start - end
      west = start
    }
    end = Math.max(end, stop)
  }
  if (first + 360 - end > gap) {
    gap = first + 360 - end
    west = first
  }
  return [
    [west, south],
    [west + 360 - gap, north],
  ]
}

export function buildFlightRouteOverlay(routes: readonly FlightRoute[]) {
  const lines: FeatureCollection<RouteLine | RouteMultiLine, RouteProperties> =
    {
      type: "FeatureCollection",
      features: [],
    }
  const labels: FeatureCollection<RoutePoint, RouteProperties> = {
    type: "FeatureCollection",
    features: [],
  }
  const longitudeIntervals: [number, number][] = []
  let south = Infinity
  let north = -Infinity

  for (const { id, from, to, count } of routes) {
    const parts = visibleArc(from, to)
    const [first, ...rest] = parts
    if (!first) continue
    const properties = { routeId: id, count }
    lines.features.push({
      type: "Feature",
      id,
      properties,
      geometry:
        rest.length === 0
          ? { type: "LineString", coordinates: first.coordinates }
          : {
              type: "MultiLineString",
              coordinates: parts.map((part) => part.coordinates),
            },
    })
    if (count > 1) {
      const longest = parts.reduce((best, part) =>
        part.length > best.length ? part : best,
      )
      labels.features.push({
        type: "Feature",
        id,
        properties,
        geometry: { type: "Point", coordinates: longest.anchor },
      })
    }

    for (const { coordinates } of parts) {
      let west = Infinity
      let east = -Infinity
      for (const [longitude, latitude] of coordinates) {
        west = Math.min(west, longitude)
        east = Math.max(east, longitude)
        south = Math.min(south, latitude)
        north = Math.max(north, latitude)
      }
      longitudeIntervals.push([west, east])
    }
  }
  return {
    lines,
    labels,
    bounds: wrappedBounds(longitudeIntervals, south, north),
  }
}
