import type {
  AirlineChoice,
  AirlinePickerCopy,
} from "@/components/routeprint/airline-picker"

export type AirportChoice = {
  id: string
  name: string
  iataCode: string | null
  icaoCode: string | null
  countryCode: string
  closed: boolean
}
export type FlightValues = {
  departure_place_id: string
  arrival_place_id: string
  departure_date: string
  arrival_date: string
  departure_time: string
  arrival_time: string
  marketing_airline_id: string
  operating_airline_id: string
  flight_number: string
  creation_request_key: string
}
export type FlightCopy = {
  airline_pending: string
  title: string
  new_title: string
  edit_title: string
  description: string
  add: string
  save: string
  saving: string
  edit: string
  delete: string
  back: string
  cancel: string
  empty: string
  empty_description: string
  additional: string
  unknown: string
  clear: string
  local_time: string
  unresolved: string
  duplicate: string
  confirm_duplicate: string
  delete_confirmation: string
  confirm_delete: string
  previous: string
  next: string
  search: string
  search_label: string
  searching: string
  search_error: string
  no_results: string
  choose_airport: string
  closed: string
  fields: Record<Exclude<keyof FlightValues, "creation_request_key">, string>
}
export type FlightRow = {
  id: string
  departureDate: string
  arrivalDate: string | null
  departureTime: string | null
  arrivalTime: string | null
  departureAirport: AirportChoice
  arrivalAirport: AirportChoice
  marketingAirline: AirlineChoice | null
  operatingAirline: AirlineChoice | null
  flightNumber: string | null
  marketingDesignator: string | null
  warnings: string[]
  urls: { show: string; edit: string; destroy: string }
}
export type FlightFormProps = {
  copy: FlightCopy
  values: FlightValues
  formErrors: Record<string, string>
  duplicates: FlightRow[]
  editing: boolean
  selected: {
    departure: AirportChoice | null
    arrival: AirportChoice | null
    marketing: AirlineChoice | null
    operating: AirlineChoice | null
  }
  airlinePicker: {
    copy: AirlinePickerCopy
    countries: { id: string; name: string }[]
  }
  urls: {
    index: string
    submit: string
    airportSearch: string
    airlineSearch: string
    airlineSubmit: string
  }
}
