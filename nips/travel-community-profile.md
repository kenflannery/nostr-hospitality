# NIP-XX: Travel & Community Profile

`draft` `optional`

**Kind:** `30602`  
**Authors:** Hospitality Libre Community  

---

## Abstract

This NIP defines an addressable, parameterized replaceable event (`kind: 30602`) for publishing a domain-specific **Travel & Community Profile** on Nostr.

By maintaining travel identity, spoken languages, and interaction modes in an independent event rather than within Kind 0 metadata, this specification:
1. **Prevents profile clobbering**: General microblogging clients (Damus, Primal, Snort) will not accidentally overwrite or erase custom travel metadata when updating a user's social bio.
2. **Maintains clean separation**: Avoids cluttering global social feeds with travel-specific logistical data.
3. **Enables cross-application discovery**: Serves hospitality networks, ridesharing apps, nomad meetups, and language exchanges through standard relay filter tags (`#language`, `#mode`, `#t`).

---

## The Travel Profile Event (Kind 30602)

Travel profiles use kind `30602`.

The event's `.content` contains the user's free-form personal travel story, philosophy, background, and expectations.

### Example Payload
```json
{
  "kind": 30602,
  "pubkey": "<user-pubkey-hex>",
  "content": "Slow traveler, software engineer, and cyclist. Passionate about cultural exchange, local food, and open-source tech. Happy to share a homecooked meal or guide visitors around my city.",
  "tags": [
    ["d", "travel-profile"],

    // 1. Demographics & Origins (Strictly Optional & Self-Sovereign)
    ["gender", "female"],
    ["birth_year", "1995"],
    ["origin_country", "DE"],
    ["origin_city", "Munich"],
    ["home_country", "FR"],
    ["home_city", "Lyon"],
    ["occupation", "Software Engineer"],

    // 2. Languages Spoken (ISO 639-1 code + optional proficiency level)
    ["language", "de", "native"],
    ["language", "en", "fluent"],
    ["language", "fr", "intermediate"],
    ["language", "es", "learning"],

    // 3. Active Interaction Modes
    ["mode", "host"],
    ["mode", "guest"],
    ["mode", "meetup"],
    ["mode", "rideshare"],

    // 4. Interests & Topics
    ["t", "cycling"],
    ["t", "hiking"],
    ["t", "cooking"],
    ["t", "nostr"],

    // 5. Travel & Lifestyle Photos (NIP-96 hosted)
    ["image", "https://image.nostr.build/alps_hiking.jpg"],
    ["image", "https://image.nostr.build/lyon_cycling.jpg"],

    // 6. NIP-39 External Identity Links (Imported Cross-Platform Trust)
    ["i", "trustroots:alice_nomad"],
    ["i", "couchsurfing:alice.traveler"],
    ["i", "warmshowers:alice_rides"],
    ["i", "github:alicenomad"]
  ],
  "created_at": 1719234800
}
```

---

## Standard Tags

### `d` (REQUIRED)
Addressable identifier. Defaults to `"travel-profile"`.

### `image` (OPTIONAL)
Direct HTTPS URLs of personal travel, adventure, and lifestyle photos hosted on decentralized media servers (e.g. `nostr.build` via NIP-96).

### `mode` (OPTIONAL)
Declares the active real-world interaction modes the user is open to participating in:
- `host` — Open to hosting travelers at home
- `guest` — Currently traveling / looking for stays
- `meetup` — Open for local hangouts, coffee, coworking, or city tours
- `rideshare` — Open for carpooling / ridesharing
- `language_exchange` — Open to practicing languages

### `language` (OPTIONAL)
Spoken languages formatted as `["language", "<iso-639-1-code>", "<proficiency>"]`:
- Levels: `native`, `fluent`, `intermediate`, `learning`

### `gender` & `birth_year` (OPTIONAL)
- `birth_year` (e.g. `"1995"`) is preferred over static integer age to allow dynamic age calculation without going stale or disclosing exact birthdays.

### `origin_country`, `origin_city`, `home_country`, `home_city` (OPTIONAL)
Distinguishes where the user grew up from their current home base.

### `i` (OPTIONAL - NIP-39)
NIP-39 identity claims linking verified profiles from legacy networks:
- `["i", "trustroots:<username>"]`
- `["i", "couchsurfing:<username>"]`
- `["i", "warmshowers:<username>"]`
- `["i", "bewelcome:<username>"]`
- `["i", "github:<username>"]`
