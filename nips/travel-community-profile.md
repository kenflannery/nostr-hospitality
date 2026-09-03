# NIP-XX: Travel & Community Profile

`draft` `optional`

**Kind:** `30602`  
**Authors:** Hospitality Libre Community  

---

## Abstract

This NIP defines an addressable, parameterized replaceable event (`kind: 30602`) for publishing a domain-specific **Travel & Community Profile** on Nostr.

By maintaining travel identity, spoken languages, and nomad mobility in an independent event rather than within Kind 0 metadata, this specification:
1. **Prevents profile clobbering**: General microblogging clients (Damus, Primal, Snort) will not accidentally overwrite or erase custom travel metadata when updating a user's social bio.
2. **Maintains clean separation**: Avoids cluttering global social feeds with travel-specific logistical data.
3. **Enables cross-application discovery**: Serves hospitality networks, nomad directories, and language exchanges through standard relay filter tags (`#language`, `#g`, `#t`).

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

    // 1. Identity & Demographics (Strictly Optional & Self-Sovereign)
    ["name", "NomadAlice"],
    ["gender", "female"],
    ["birth_year", "1995"],
    ["birth_month", "4"],
    ["birth_day", "12"],
    ["occupation", "Software Engineer"],
    ["education", "B.Sc. Computer Science"],

    // 2. Geography & Mobility (ISO 3166-1 alpha-2 2-letter uppercase codes)
    ["origin_country", "DE"],
    ["origin_city", "Munich"],
    ["home_country", "FR"],
    ["home_city", "Lyon"],
    ["current_country", "MX"],
    ["current_city", "Oaxaca"],

    // 3. Spatial Geohash Tags (Active Presence Location: Oaxaca ~5km neighborhood box)
    ["g", "9g3w8"],
    ["g", "9g3w"],
    ["g", "9g3"],

    // 4. Languages Spoken (ISO 639-1 code + optional proficiency level)
    ["language", "de", "native"],
    ["language", "en", "fluent"],
    ["language", "fr", "intermediate"],
    ["language", "es", "learning"],

    // 5. Interests, Activities, & Topics
    ["t", "meetup"],
    ["t", "cycling"],
    ["t", "hiking"],
    ["t", "cooking"],
    ["t", "nostr"],

    // 6. Travel & Lifestyle Photos (NIP-96 hosted)
    ["image", "https://image.nostr.build/alps_hiking.jpg"],
    ["image", "https://image.nostr.build/lyon_cycling.jpg"],

    // 7. Linked Hospitality & Social Networks
    ["network", "triphopping", "alice_nomad"],
    ["network", "couchers", "alice_traveler"],
    ["network", "trustroots", "alice_nomad"],
    ["network", "couchsurfing", "alice.traveler"],
    ["network", "warmshowers", "alice_rides"],
    ["network", "github", "alicenomad"]
  ],
  "created_at": 1719234800
}
```

---

## Standard Tags

### `d` (REQUIRED)
Addressable identifier. Defaults to `"travel-profile"`.

### `name` (OPTIONAL)
Traveler name, nickname, or trail name (e.g. `"NomadAlice"`, `"Ken"`). Allows travelers to use a friendly first name or trail identity distinct from their formal Kind 0 identity.

### `birth_year`, `birth_month`, `birth_day` (OPTIONAL)
Self-sovereign date of birth granularity:
- `birth_year` (e.g. `"1995"`): Preferred over static integer age to allow dynamic age calculation without going stale or disclosing exact birthdays.
- `birth_month` (1-12) and `birth_day` (1-31): Optional tags for users who wish to provide exact birthday granularity.

### Location Tags (`origin_*`, `home_*`, `current_*`) (OPTIONAL)
- `origin_country` & `origin_city`: Where the user grew up / cultural roots.
- `home_country` & `home_city`: Current fixed home base / residence.
- `current_country` & `current_city`: Active nomad or travel location while on the road.
- **Country Code Standard**: Country fields **MUST** use standard 2-letter uppercase ISO 3166-1 alpha-2 codes (e.g. `"US"`, `"MX"`, `"CA"`, `"DE"`, `"FR"`).

### `g` (OPTIONAL)
Cascading geohash tags representing the traveler's **active physical presence** (`current` location if set, otherwise `home` base).
- Geohashes **MUST** adhere to privacy bounding between **3 to 5 characters** (defaulting to 5 characters `~5km` neighborhood area; 4 characters `~20-40km` city area; 3 characters `~150km` regional area).
- `origin` locations **MUST NEVER** be tagged with `g` to prevent false spatial discovery matches.

### `language` (OPTIONAL)
Spoken languages formatted as `["language", "<iso-639-1-code>", "<proficiency>"]`:
- Levels: `native`, `fluent`, `intermediate`, `learning`

### `t` (OPTIONAL)
Hashtags and topics declaring passions, hobbies, and community activities (e.g. `["t", "meetup"]`, `["t", "cycling"]`, `["t", "hitchhiking"]`).

### `image` (OPTIONAL)
Direct HTTPS URLs of personal travel, adventure, and lifestyle photos hosted on decentralized media servers (e.g. `nostr.build` via NIP-96).
- **Primary / Featured Image**: The **first `image` tag** in the event tags array is treated as the traveler's primary featured photo for profile previews and search cards. Subsequent `image` tags form the adventure photo gallery in order.

### `network` (OPTIONAL)
Linked hospitality, travel, and social network accounts formatted as `["network", "<platform>", "<username>", "<optional_url_or_proof>"]`:
- Platforms: `triphopping`, `couchers`, `trustroots`, `couchsurfing`, `warmshowers`, `bewelcome`, `github`, `twitter`, `x`
- Allows self-asserted cross-network identity and reputation discovery without misusing NIP-39 proof contracts.
