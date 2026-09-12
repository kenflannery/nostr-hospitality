# Community Labeling, Reporting, & Decentralized Moderation

`draft` `optional`

This specification defines the conventions used by **Hospitality Libre** for decentralized trust, community trait labeling, safety advisories, and reporting on Nostr, integrating **NIP-32** (Labeling), **NIP-56** (Reporting), and **NIP-51** (Lists & Sets).

---

## 1. Motivation & Architecture

Centralized hospitality networks (Couchsurfing, Airbnb) enforce binary, opaque moderation from corporate support desks:
1. **Opaque Whisper Networks**: Travelers feeling uncomfortable or observing boundary issues often hesitate to file formal disputes or public reviews for fear of retaliation, leading to private "whisper networks" that leave new travelers vulnerable.
2. **Arbitrary Censorship**: Central platforms unilaterally censor reviews or ban accounts with zero audit trail.
3. **Reputation Washing**: In flat review systems, 30 superficial reviews can completely bury critical safety alerts.

Hospitality Libre establishes a multi-layered, decentralized trust architecture:
- **Formal Verified Encounters**: Kind 7654 Interaction References for full stays with dates, roles, and narrative.
- **Lightweight Endorsements & Advisories**: Kind 1985 (NIP-32) single-tag labels for traits, rhythm, and safety notes without requiring a full stay.
- **Adversarial Violation Reporting**: Kind 1984 (NIP-56) standard reports targeting pubkeys or specific events.
- **Personal Filtering & Blocklists**: Kind 10000 (NIP-51) replaceable mute lists synced across the Nostr ecosystem.
- **Customizable Caution Dictionaries**: Kind 30015 (NIP-51) interest sets defining which tags are treated as cautionary in the user's interface.

---

## 2. NIP-32 Community Labeling (`kind: 1985`)

A community label is an individual assertion published by an author regarding a subject pubkey (and optionally a specific listing/event).

### Event Structure
```json
{
  "kind": 1985,
  "pubkey": "<author-pubkey-hex>",
  "content": "Made handmade pasta and shared great cycling routes.",
  "tags": [
    ["L", "#t"],
    ["l", "great_cook", "#t"],
    ["p", "<subject-pubkey-hex>"]
  ],
  "created_at": 1719234800
}
```

### Tag Conventions
- `["L", "#t"]` (**REQUIRED**): Standard NIP-32 namespace indicating a topic, hashtag, or trait.
- `["l", "<tag_name>", "#t"]` (**REQUIRED**): The lowercased, trimmed label value (e.g. `great_cook`, `creepy`, `night_owl`).
- `["p", "<subject-pubkey-hex>"]` (**REQUIRED**): The pubkey receiving the label.
- `["e", "<event-id-hex>"]` (**OPTIONAL**): The specific listing or request event being labeled.
- `["a", "<coordinate>"]` (**OPTIONAL**): The parameterized coordinate if labeling an addressable listing.

### Deletion (NIP-09)
Because each label is published as its own independent `kind: 1985` event, authors retain sovereign control and can retract or delete individual labels at any time by issuing a standard **Kind 5** deletion request referencing the label event ID.

---

## 3. Two-Tier UI Presentation & Safety Isolation

To prevent reputation washing, clients **MUST NOT** merge safety or boundary warnings into a flat word cloud with casual lifestyle traits:

1. **Tier 1 (Traits & Rhythm)**: Positive endorsements and lifestyle alignment tags (`great_cook`, `clean`, `communicative`, `night_owl`, `early_riser`, `bikepacker`). Displayed as neutral or positive community trait chips.
2. **Tier 2 (Community Advisories & Boundaries)**: Safety and boundary warnings (`creepy`, `thief`, `unresponsive`, `cancelled_last_minute`, `boundary_issues`, `demanded_cash`). Displayed in a dedicated, high-contrast Community Advisory card at the top of the reputation section, regardless of how many positive tags exist.

---

## 4. Customizable Cautionary Sets (`kind: 30015`)

Clients ship with built-in default cautionary tags:
```
creepy, thief, unresponsive, cancelled_last_minute, aggressive, demanded_cash, boundary_issues, messy, unsafe, scam
```

Users can define or customize their personal caution dictionary by publishing a parameterized replaceable **Kind 30015** event:
```json
{
  "kind": 30015,
  "pubkey": "<user-pubkey-hex>",
  "tags": [
    ["d", "hospitality-cautionary-tags"],
    ["t", "creepy"],
    ["t", "thief"],
    ["t", "unresponsive"],
    ["t", "cancelled_last_minute"],
    ["t", "loud_music"]
  ],
  "content": ""
}
```

---

## 5. NIP-56 Reporting (`kind: 1984`)

When reporting severe violations (illegal acts, explicit content, bot spam), clients publish a standard NIP-56 event:
```json
{
  "kind": 1984,
  "pubkey": "<reporter-pubkey-hex>",
  "content": "Commercial spam links posted repeatedly on listing description.",
  "tags": [
    ["p", "<offender-pubkey-hex>", "spam"],
    ["e", "<offending-listing-event-id>", "spam"]
  ]
}
```

### Standard Violation Categories
- `spam`: Unsolicited commercial promotions or bot traffic.
- `nudity`: Non-consensual or explicit sexual depictions.
- `profanity`: Hate speech, harassment, or abusive attacks.
- `illegal`: Content violating applicable legal statutes.
- `impersonation`: Falsely claiming the identity of another entity.
- `other`: Other platform violations.

---

## 6. NIP-51 Personal Muting (`kind: 10000`)

To fulfill Apple App Store Guideline 1.2 and empower personal agency, clients maintain the user's personal blocklist:
```json
{
  "kind": 10000,
  "pubkey": "<user-pubkey-hex>",
  "tags": [
    ["p", "<muted-pubkey-1>"],
    ["p", "<muted-pubkey-2>"]
  ],
  "content": ""
}
```
Clients immediately suppress listings, messages, and profile details authored by any pubkey listed in the user's active Kind 10000 event.
