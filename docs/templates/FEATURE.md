# Feature: <name>

## Purpose
<one paragraph: user value, who uses it>

## Data policy
- Policy: `CacheOnly | OutboxWrite | OnlineOnly`
- Sync scope: `mirror | queryScoped` (reason: ...)
- TTL: <e.g. 5 min> · Requires auth: <yes/no>
- Conflict policy (OutboxWrite only): `serverWins | clientWins | lastWriteWins | fieldMerge | askUser` (reason: ...)
- Deletion strategy: `softDelete | idReconcile | fullRefresh`

## Data decision record (docs/15 §7)
| Entity / operation | Q1–Q6 answers | Resulting source | Scope/TTL | Freshness guard |
|---|---|---|---|---|

## Directus
| Collection | Fields requested | Filters | Notes |
|---|---|---|---|

Realtime channels: <none | list>

## Entities and tables
| Entity | Table | Indexes | Notes |
|---|---|---|---|

## Depends on (other features' domain only)
<none | list>

## Routes
| Route | Page | Params | Guards |
|---|---|---|---|

## Use cases
| Use case | Repository method | Business rule it owns (or "pass-through") |
|---|---|---|

## Blocs
| Bloc | Events | Transformers | State highlights |
|---|---|---|---|

## Offline behavior per screen
| Screen | No data + offline | Data + offline | Stale | Pending/failed sync |
|---|---|---|---|---|

## Tests
<list of test files and scenarios covered; link to sync scenarios from docs/09 §7 that apply>

## Open questions / assumptions
<none | list>
