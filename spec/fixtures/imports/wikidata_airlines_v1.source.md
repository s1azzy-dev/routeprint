# Wikidata airlines v1 fixture provenance

- Source: https://query.wikidata.org/sparql
- Query: `config/imports/wikidata_airlines_v1.sparql`
- Captured: 2026-08-07
- Format: Wikidata Query Service SPARQL results JSON
- License: Wikidata structured data is available under CC0 1.0. Attribution is
  not required, but Routeprint records Wikidata as the source.
- License reference: https://www.wikidata.org/wiki/Wikidata:Licensing
- Access guidance: https://www.wikidata.org/wiki/Wikidata:Data_access
- Selected QIDs: `Q100153989`, `Q101208211`, `Q101208285`, `Q102428077`, and
  `Q1156345`.
- The bounded fixture uses the production v1 projection with a `VALUES` clause
  for those QIDs in place of the production keyset-page subquery. It otherwise
  preserves the response bindings unchanged.

## Profile snapshot

The direct-instance eligibility query (`P31 = Q46970`) returned 5,678 airlines
at capture time. Of those, 5,217 had an English label, 2,722 an IATA
designator, 3,367 an ICAO designator, 5,279 a country, 4,494 an inception value,
and 2,696 a concrete dissolution value. Only 56 non-deprecated IATA/ICAO
statements carried a start or end qualifier.

The sample intentionally proves:

- a name-and-country-only record;
- a shared `UB`/`UBA` designator across historical and current QIDs;
- a record without an English name, which is retained in raw input but is not
  eligible for automatic publication;
- month, year, and day time precision; and
- day-precise and coarse designator validity qualifiers.

Wikidata time precision is retained in raw/normalized source evidence. Only
precision `11` (day) may populate canonical designator validity. Precision `9`
(year) or `10` (month) remains nullable canonically instead of being presented
as an exact January/first-of-month date. Inception and dissolution dates remain
source evidence rather than new canonical airline columns. A concrete past
`P576` value may prove that an airline is inactive, but absence of `P576` does
not prove that it is active.
