# NIP-99 Extension: Hospitality Classified Listings (Offers & Requests)

`draft` `optional`

**Kind:** `30402` (Active) / `30403` (Draft)  
**Standard Base:** [NIP-99 (Classified Listings)](https://github.com/nostr-protocol/nips/blob/master/99.md)  
**Authors:** Hospitality Libre Community  

---

## Abstract

This document specifies how **NIP-99 Classified Listings** (`kind: 30402`) are tailored for sovereign, decentralized hospitality networks (open Couchsurfing).

It establishes bidirectional classified exchange:
1. **Hosting Offers**: Hosts offering accommodation (couches, private rooms, house swaps, tent space).
2. **Stay Requests (Public Trips)**: Travelers posting destination stay requests with date ranges and party sizes.
3. **Temporal Availability (`start` / `end`)**: Standardized unix timestamps for trip schedules and temporary hosting windows.
4. **Privacy-Preserving Geohashes**: Bounding host and traveler coordinates to 3 to 5 character geohashes (defaulting to 5 characters, ~5km neighborhood/district box) with cascading prefix tags.
5. **Tri-State Preferences & Household Schema**: A structured schema for sleeping arrangements, household reality, accessibility, and house rules.
6. **Non-Commercial Open Access**: Standardized zero-pricing tags for gift-economy hospitality.

---

## Classification Topic Tags (`t`)

Listings declare their hospitality domain and listing intent via standard `t` tags:

| Listing Intent | Topic Tags | Description |
|---|---|---|
| **Hosting Offer** | `["t", "hospitality"]`<br/>`["t", "hospitality-offer"]`<br/>`["t", "Home"]` | Host offering accommodation |
| **Stay Request** | `["t", "hospitality"]`<br/>`["t", "hospitality-request"]` | Traveler seeking accommodation / host |

### Absence Fallback Rule (Backwards Compatibility)
If a `30402` listing includes `["t", "hospitality"]` but omits both `hospitality-offer` and `hospitality-request` tags, clients **MUST** treat the listing as a **Hosting Offer** (`hospitality-offer`).

---

## Temporal Date Tags (`start` / `end`)

To support time-bound travel plans and temporary hosting availability windows without deleting historical records:

| Tag | Value | Description |
|---|---|---|
| `start` | Unix timestamp string (e.g. `"1793577600"`) | Traveler arrival / check-in date, or start of temporary hosting window |
| `end` | Unix timestamp string (e.g. `"1793836800"`) | Traveler departure / check-out date, or end of temporary hosting window |

- **Open-ended hosting**: Ongoing residential hosts omit `start` and `end`.
- **Relay History vs Expiration**: Instead of requiring NIP-40 auto-deletion, clients use `end` to transition listings from active discovery to past travel journals, preserving Kind 7654 review links.

---

## Geohash Privacy Policy

To protect host and traveler safety and prevent public broadcasting of exact residential or lodging coordinates:
- **Configurable Precision (3 to 5 characters)**:
  - **Precision 5 (Default / Recommended)**: ~4.9km × 4.9km bounding box (~5km area). Identifies the neighborhood or district while completely concealing exact street addresses.
  - **Precision 4**: ~39km × 19.5km bounding box (~20–40km area). Covers a city or metropolitan area.
  - **Precision 3**: ~156km × 156km bounding box (~150km area). Broad regional area for maximum geographic obscurity.
- **Cascading `g` Tags**: Listings **MUST** emit hierarchical prefix `g` tags for multi-resolution relay search:
  ```json
  ["g", "c"],
  ["g", "c2"],
  ["g", "c23"],
  ["g", "c23n"],
  ["g", "c23nb"]
  ```
- **Approximate Center (`origin_lat` / `origin_lon`)**: Coordinates point to the centroid of the geohash bounding box, enabling simple map placement without exposing exact street locations.

---

## Preferences & Household Schema

All boolean and categorical preference tags follow **strict tri-state nullability**:
- **Null / Absent**: Unspecified / Unknown (**no tag is emitted**)
- **`"true"`**: Explicitly affirmative / allowed
- **`"false"`**: Explicitly prohibited / negative

### Standard Tags

| Tag Name | Value / Allowed Types | Description |
|---|---|---|
| `start` | Unix timestamp string | Arrival date or temporary hosting start |
| `end` | Unix timestamp string | Departure date or temporary hosting end |
| `max_guests` / `guests` | `"1"`, `"2"`, `"3"`, etc. | Maximum guests accommodated (offer) or traveling party size (request) |
| `last_minute` | `"true"` \| `"false"` | Open to same-day / short-notice requests |
| `wheelchair` | `"true"` \| `"false"` | Step-free or accessible accommodation needed / offered |
| `tent_camping` | `"true"` \| `"false"` | Yard / lawn space available or acceptable for tents |
| `kids_allowed` | `"true"` \| `"false"` | Open to hosting / traveling with children |
| `pets_allowed` | `"true"` \| `"false"` | Open to hosting / traveling with pets |
| `drinking_allowed` | `"true"` \| `"false"` | Guests permitted to drink alcohol / traveler drinks |
| `smoking_allowed` | `"no"` \| `"outside"` \| `"yes"` | Smoking policy for guests / traveler smoking habit |
| `sleeping_arrangement`| `"private_room"` \| `"shared_room"` \| `"couch"` \| `"common_room"` \| `"tent_space"` | Sleeping arrangement offered / acceptable |
| `parking` | `"none"` \| `"free_on_premises"` \| `"street"` \| `"paid"` | Vehicle parking accessibility |
| `parking_details` | string (e.g. `"Driveway parking available"`) | Specific instructions for guest vehicles |
| `has_housemates` | `"true"` \| `"false"` | Host lives with other housemates/roommates |
| `has_kids` | `"true"` \| `"false"` | Host has children living in the household |
| `has_pets` | `"true"` \| `"false"` | Host has animals/pets on the property |
| `host_drinks` | `"true"` \| `"false"` | Host drinks alcohol at home |
| `host_smokes` | `"no"` \| `"outside"` \| `"yes"` | Host smokes at home |

---

## Example Payloads

### 1. Hosting Offer Example
```json
{
  "kind": 30402,
  "pubkey": "<host-pubkey-hex>",
  "content": "Cozy spare bedroom in central Seattle. Close to light rail, coffee shops, and parks. Always happy to share local travel tips!",
  "tags": [
    ["d", "<host-pubkey>-home"],
    ["title", "Cozy Guest Room in Seattle"],
    ["summary", "Private room for 1-2 travelers near transit."],
    ["location", "Seattle, Washington, United States"],
    ["status", "active"],
    ["price", "0", "USD"],
    ["t", "hospitality"],
    ["t", "hospitality-offer"],
    ["t", "Home"],
    ["g", "c"],
    ["g", "c2"],
    ["g", "c23"],
    ["g", "c23n"],
    ["g", "c23nb"],
    ["origin_lat", "47.6367"],
    ["origin_lon", "-122.3438"],
    ["max_guests", "2"],
    ["last_minute", "true"],
    ["wheelchair", "false"],
    ["tent_camping", "false"],
    ["kids_allowed", "true"],
    ["pets_allowed", "false"],
    ["drinking_allowed", "true"],
    ["smoking_allowed", "outside"],
    ["sleeping_arrangement", "private_room"],
    ["parking", "free_on_premises"],
    ["parking_details", "Driveway parking space in front of garage"],
    ["has_housemates", "false"],
    ["has_kids", "false"],
    ["has_pets", "true"],
    ["host_drinks", "true"],
    ["host_smokes", "no"],
    ["published_at", "1719234800"]
  ],
  "created_at": 1719234800
}
```

### 2. Traveler Stay Request Example (Public Trip)
```json
{
  "kind": 30402,
  "pubkey": "<traveler-pubkey-hex>",
  "content": "Visiting Chicago for the architecture biennial and local jazz scene. Looking for a host or local meetups near downtown/Lincoln Park!",
  "tags": [
    ["d", "trip-chicago-20261102"],
    ["title", "Visiting Chicago for Architecture & Jazz"],
    ["summary", "Solo traveler seeking 3 nights in Chicago."],
    ["location", "Chicago, Illinois, United States"],
    ["status", "active"],
    ["price", "0", "USD"],
    ["t", "hospitality"],
    ["t", "hospitality-request"],
    ["g", "d"],
    ["g", "dp"],
    ["g", "dp3"],
    ["g", "dp3w"],
    ["g", "dp3wh"],
    ["origin_lat", "41.8781"],
    ["origin_lon", "-87.6298"],
    ["start", "1793577600"],
    ["end", "1793836800"],
    ["max_guests", "1"],
    ["pets_allowed", "false"],
    ["wheelchair", "false"],
    ["published_at", "1719234800"]
  ],
  "created_at": 1719234800
}
```
