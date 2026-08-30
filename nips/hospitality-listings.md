# NIP-99 Extension: Hospitality Hosting Profile

`draft` `optional`

**Kind:** `30402` (Active) / `30403` (Draft)  
**Standard Base:** [NIP-99 (Classified Listings)](https://github.com/nostr-protocol/nips/blob/master/99.md)  
**Authors:** Hospitality Libre Community  

---

## Abstract

This document specifies how **NIP-99 Classified Listings** (`kind: 30402`) are tailored for open, sovereign hospitality and home sharing networks (decentralized Couchsurfing).

It defines:
1. **Privacy-Preserving Geohashes**: Bounding host coordinates strictly to 4-character geohashes (~20–40km) with cascading prefix tags.
2. **Tri-State Household & Hosting Preferences**: A structured schema for sleeping arrangements, household reality, accessibility, and house rules.
3. **Non-Commercial Open Access**: Standardized zero-pricing tags for gift-economy hospitality.

---

## Category Tags

Hospitality listings publish standard NIP-99 category topic tags:
```json
["t", "hospitality"],
["t", "Home"]
```

---

## Geohash Privacy Policy

To protect host safety and prevent public broadcasting of exact residential street coordinates:
- **Maximum Geohash Precision**: Geohashes **MUST NOT** exceed **4 characters** (e.g. `c23n`), representing an approximate ~39km × 19.5km bounding box.
- **Cascading `g` Tags**: Listings **MUST** emit hierarchical prefix `g` tags for multi-resolution relay search:
  ```json
  ["g", "c"],
  ["g", "c2"],
  ["g", "c23"],
  ["g", "c23n"]
  ```
- **Approximate Center (`origin_lat` / `origin_lon`)**: Coordinates point to the centroid of the 4-character geohash bounding box, enabling simple map placement without exposing exact home locations.

---

## Hosting Preferences & Household Schema

All boolean and categorical preference tags follow **strict tri-state nullability**:
- **Null / Absent**: Unspecified / Unknown (**no tag is emitted**)
- **`"true"`**: Explicitly affirmative / allowed
- **`"false"`**: Explicitly prohibited / negative

### Standard Tags

| Tag Name | Value / Allowed Types | Description |
|---|---|---|
| `max_guests` | `"1"`, `"2"`, `"3"`, etc. | Maximum number of simultaneous guests accommodated |
| `last_minute` | `"true"` \| `"false"` | Open to same-day / short-notice requests |
| `wheelchair` | `"true"` \| `"false"` | Step-free or accessible accommodation |
| `tent_camping` | `"true"` \| `"false"` | Yard / lawn space available for pitching tents |
| `kids_allowed` | `"true"` \| `"false"` | Open to hosting families with children |
| `pets_allowed` | `"true"` \| `"false"` | Open to hosting guests with pets |
| `drinking_allowed` | `"true"` \| `"false"` | Guests permitted to drink alcohol |
| `smoking_allowed` | `"no"` \| `"outside"` \| `"yes"` | Smoking policy for guests |
| `sleeping_arrangement`| `"private_room"` \| `"shared_room"` \| `"couch"` \| `"common_room"` \| `"tent_space"` | Sleeping arrangement offered |
| `parking` | `"none"` \| `"free_on_premises"` \| `"street"` \| `"paid"` | Vehicle parking accessibility |
| `parking_details` | string (e.g. `"Driveway parking available"`) | Specific instructions for guest vehicles |
| `has_housemates` | `"true"` \| `"false"` | Host lives with other housemates/roommates |
| `has_kids` | `"true"` \| `"false"` | Host has children living in the household |
| `has_pets` | `"true"` \| `"false"` | Host has animals/pets on the property |
| `host_drinks` | `"true"` \| `"false"` | Host drinks alcohol at home |
| `host_smokes` | `"no"` \| `"outside"` \| `"yes"` | Host smokes at home |

---

## Example Payload
```json
{
  "kind": 30402,
  "pubkey": "<host-pubkey-hex>",
  "content": "Cozy spare bedroom in central Seattle. Close to light rail, coffee shops, and parks. Always happy to share local travel tips!",
  "tags": [
    ["d", "<unique-d-tag>"],
    ["title", "Cozy Guest Room in Seattle"],
    ["summary", "Private room for 1-2 travelers near transit."],
    ["location", "Seattle, Washington, United States"],
    ["status", "active"],
    ["price", "0", "USD"],
    ["t", "hospitality"],
    ["t", "Home"],
    ["g", "c"],
    ["g", "c2"],
    ["g", "c23"],
    ["g", "c23n"],
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
