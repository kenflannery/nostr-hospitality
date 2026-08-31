# Hospitality Libre (Flutter v1)

**Hospitality Libre** is a **100% Nostr-native hospitality network**: an open, decentralized Couchsurfing-style application built in Flutter with **zero proprietary backend, and zero centralized user databases**.

The app is the **reference implementation** establishing open Nostr protocol standards for decentralized accommodation, home sharing, traveler profiles, and interpersonal references.

---

## Key Features

- **Sovereign Identity**: Sign in with an `nsec` or generate a new Nostr keypair. Your cryptographic identity (npub/nsec) is your passport across the decentralized web.
- **Kind 0 User Profiles**: Standard Nostr profile metadata (name, display name, picture, banner, bio, NIP-05, website). Safe, non-destructive profile edits preserve unmanaged fields.
- **Travel & Community Profiles (Kind 30602)**: Clobber-proof domain profile preserving languages spoken, interaction modes (host, guest, meetup, rideshare, language exchange), demographics, and NIP-39 legacy trust proofs.
- **NIP-99 Hospitality Hosting Offers**: Hosts publish accommodations (couch, spare room, house swap, tent space) as addressable NIP-99 Classified Listings (`kind: 30402`).
- **Comprehensive Hosting Preferences**: Standardized tags for sleeping arrangements, max guests, last-minute requests, wheelchair accessibility, kids, pets, drinking, smoking, and parking with strict tri-state nullability.
- **Geohash Privacy & Cascading Tags**: Adheres strictly to the 4-character geohash privacy policy (`g` tag truncated to 4 chars for ~20-40km bounding area) to protect host home privacy while enabling spatial indexing across relays.
- **Interactive Map & Feed Views**: Discover page features dual **Interactive Map View** and **List View** powered by `flutter_map` with OpenStreetMap raster tiles, Nominatim geocoding recentering, and custom accommodation markers.
- **Interaction References (Kind 7654)**: Portable, historical statements between hosts, guests, and travelers (`kind: 7654`). Builds genuine social reputation that travels with users across any Nostr application.
- **Factual Reputation Summaries**: Objective aggregations of references (positive / neutral / negative subtotals and host/guest counts) without proprietary star averages or numeric scoring.
- **NIP-17 Private Direct Messaging**: End-to-end encrypted private messaging using NIP-59 gift-wrapped rumors, allowing hosts and travelers to coordinate stays directly.
- **Built-in Developer Reference Guide**: In-app protocol specifications page detailing JSON schemas, tag structures, and copyable payloads for interoperable client developers.

---

## Nostr Protocols & NIP Implementation

| Kind | Protocol / Specification | Purpose | Formal Spec |
|---|---|---|---|
| `0` | NIP-01 User Metadata | Base profile identity, avatar, display name, bio, and NIP-05 verification | [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md) |
| `30602` | Travel & Community Profile (Draft NIP) | Parameterized profile: languages, demographics, interaction modes, and NIP-39 identity links | [`nips/travel-community-profile.md`](nips/travel-community-profile.md) |
| `30402` | NIP-99: Hospitality Classified Listings | Addressable hospitality hosting offers and tri-state household preferences | [`nips/hospitality-listings.md`](nips/hospitality-listings.md) |
| `7654` | Interaction References (Draft NIP) | Portable interpersonal references, reviews, and historical interaction statements | [`nips/interaction-references.md`](nips/interaction-references.md) |
| `1059` / `13` / `14` | NIP-17 / NIP-59 Private Messaging | Gift-wrapped end-to-end encrypted direct messaging | [NIP-17](https://github.com/nostr-protocol/nips/blob/master/17.md) / [NIP-59](https://github.com/nostr-protocol/nips/blob/master/59.md) |
| `10050` / `10002` | NIP-17 / NIP-65 Relay Lists | Outbox and DM relay discoverability | [NIP-65](https://github.com/nostr-protocol/nips/blob/master/65.md) |

---

## Protocol Specifications & Developer Proposals

Formal NIP proposals and reference documents for developers building interoperable clients are stored in the [`nips/`](nips/) directory:

1. **[`nips/hospitality-listings.md`](nips/hospitality-listings.md)**: NIP-99 Hospitality Hosting Profile (`kind: 30402`), 4-char geohash privacy standard, and tri-state hosting preferences.
2. **[`nips/travel-community-profile.md`](nips/travel-community-profile.md)**: Travel & Community Profile (`kind: 30602`), interaction modes, language proficiencies, and NIP-39 cross-network links.
3. **[`nips/interaction-references.md`](nips/interaction-references.md)**: Interaction References (`kind: 7654`), subject tags, interaction context, roles, and sentiment nullability rules.

---

### 1. Hospitality Hosting Offers — NIP-99 (Kind 30402)

Hosting offers are published as parameterized addressable events (`kind: 30402`) following the **NIP-99 Classified Listings** specification.

#### Classification Topics
Hospitality listings are identified by standard topic tags:
```json
["t", "hospitality"],
["t", "Home"]
```

#### Geohash Precision & Privacy Policy
- **Kind 30402 (Hospitality Classifieds)**: Geohashes are strictly truncated to a **maximum of 4 characters** (~39km x 19.5km bounding box) to protect the exact street address and privacy of hosts.
- To enable multi-level proximity queries, listings publish cascading `g` tags (e.g. `["g", "c"]`, `["g", "c2"]`, `["g", "c23"]`, `["g", "c23n"]`).
- `origin_lat` / `origin_lon` represent the approximate center coordinates of the 4-char geohash box for simple map client pin placement.

#### Hosting Preferences & Home Environment Tags
All preference tags follow **strict tri-state nullability** (absence of tag = unspecified; `"true"` = yes; `"false"` = no):

| Tag Name | Value / Allowed Types | Description |
|---|---|---|
| `max_guests` | `"1"`, `"2"`, `"3"`, etc. | Maximum number of simultaneous guests accommodated |
| `last_minute` | `"true"` \| `"false"` | Open to same-day / short-notice requests |
| `wheelchair` | `"true"` \| `"false"` | Step-free or accessible access |
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

#### Example Kind 30402 Listing Event
```json
{
  "kind": 30402,
  "pubkey": "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
  "content": "Quiet guest room in Ballard, Seattle. Close to transit, coffee shops, and parks.",
  "tags": [
    ["d", "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798-home"],
    ["title", "Cozy Room in Seattle"],
    ["summary", "Private guest room for 1-2 travelers near transit."],
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
    ["kids_allowed", "true"],
    ["pets_allowed", "false"],
    ["drinking_allowed", "true"],
    ["smoking_allowed", "outside"],
    ["sleeping_arrangement", "private_room"],
    ["parking", "free_on_premises"],
    ["has_housemates", "false"],
    ["has_kids", "false"],
    ["has_pets", "true"],
    ["host_drinks", "true"],
    ["host_smokes", "no"],
    ["published_at", "1719234800"]
  ]
}
```

*Status Semantics*: `active` indicates the host is accepting guests; `sold` indicates the offer is currently inactive or closed.

---

### 2. Interaction References — Draft NIP (Kind 7654)

References are **regular, historical Nostr events** (not addressable or replaceable).

> **Generic Design**: While `nostr-hospitality` focuses on travel and hosting, **Kind 7654 is designed generically** so marketplaces, service networks, and social clients can publish and consume compatible references.

#### Core Tags
- `p` (**REQUIRED**): Exactly one pubkey tag identifying the person being referenced.
- `context` (**OPTIONAL**): Nature of the interaction (`hospitality`, `meeting`, `travel`, `transaction`, `service`, `work_exchange`, `other`).
- `role` (**OPTIONAL**): Author's role in the interaction (`host`, `guest`, `traveler`, `buyer`, `seller`, `customer`, `provider`, `other`).
- `sentiment` (**OPTIONAL**): Coarse assessment (`positive`, `neutral`, `negative`). Absence of sentiment is strictly `null` and **MUST NOT** be counted as neutral.
- `t` (**OPTIONAL**): Arbitrary interaction trait and label hashtags (`communicative`, `clean`, `inspiring`, `respectful`, `prompt`).
- `a` (**OPTIONAL**): Addressable coordinate of an associated object (e.g. `30402:<host-pubkey>:<d-tag>`).
- `e` (**OPTIONAL**): Associated specific event ID.

#### Example Kind 7654 Reference Event
```json
{
  "kind": 7654,
  "pubkey": "c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5",
  "content": "Bob was a fantastic host. He showed me around town, shared great meals, and made me feel completely welcome.",
  "tags": [
    ["p", "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"],
    ["context", "hospitality"],
    ["role", "guest"],
    ["sentiment", "positive"],
    ["t", "communicative"],
    ["t", "clean"],
    ["t", "great_cook"],
    ["a", "30402:79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798:79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798-home"]
  ]
}
```

---

### 3. Travel & Community Profile — Draft NIP (Kind 30602)

To prevent standard social clients from clobbering domain-specific profile data in Kind 0, user travel preferences, languages, and interaction modes are published as addressable **Kind 30602** events.

#### Core Tags
- `d` (**REQUIRED**): Profile identifier (defaults to `travel-profile`).
- `mode` (**OPTIONAL**): Active interaction modes (`host`, `guest`, `meetup`, `rideshare`, `language_exchange`).
- `language` (**OPTIONAL**): Spoken languages `["language", "<code>", "<proficiency>"]` (e.g. `["language", "en", "fluent"]`).
- `origin_country` / `origin_city`: Origin hometown.
- `home_country` / `home_city`: Current residence / base city.
- `gender` / `birth_year`: Optional demographics (`birth_year` calculates age dynamically).
- `occupation` / `education`: Professional / personal background.
- `t`: Interests / Topics (`cycling`, `hiking`, `nostr`).
- `image`: Direct photo image URLs of adventures, travels, and lifestyle (`["image", "<url>"]`).
- `network`: Linked hospitality and travel community profiles (`["network", "<platform>", "<username>"]`).

#### Example Kind 30602 Profile Event
```json
{
  "kind": 30602,
  "pubkey": "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
  "content": "Slow traveler, software engineer, and cyclist. Passionate about cultural exchange and decentralized tech.",
  "tags": [
    ["d", "travel-profile"],
    ["gender", "female"],
    ["birth_year", "1995"],
    ["origin_country", "DE"],
    ["origin_city", "Munich"],
    ["home_country", "FR"],
    ["home_city", "Lyon"],
    ["occupation", "Software Engineer"],
    ["language", "de", "native"],
    ["language", "en", "fluent"],
    ["language", "fr", "intermediate"],
    ["mode", "host"],
    ["mode", "guest"],
    ["mode", "meetup"],
    ["t", "cycling"],
    ["t", "hiking"],
    ["image", "https://image.nostr.build/adventure1.jpg"],
    ["image", "https://image.nostr.build/adventure2.jpg"],
    ["network", "triphopping", "alice_nomad"],
    ["network", "couchers", "alice_nomad"],
    ["network", "trustroots", "alice_nomad"],
    ["network", "couchsurfing", "alice.traveler"]
  ]
}
```

---

### 4. Private Messaging — NIP-17

Direct messages between hosts and guests utilize NIP-17 gift-wrapped rumors:
- **Gift Wrap (`kind: 1059`)**: Ephemeral envelope signed by a temporary key.
- **Seal (`kind: 13`)**: Inner envelope signed by sender containing encrypted rumor.
- **Rumor (`kind: 14`)**: Plaintext message payload and timestamp.

---

## Running and Testing

### Prerequisites
- Flutter 3.24+ / Dart 3.5+

### Installation & Execution
```bash
# Get dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run unit tests
flutter test

# Run app locally
flutter run -d chrome
```

---

## Live Deployment (GitHub Pages)

This repository includes an automated GitHub Actions workflow (`.github/workflows/deploy.yml`) that automatically tests, compiles, and deploys the web client to **GitHub Pages** on every push to `main`.

### To Enable on your GitHub Repository:
1. Navigate to **Settings** > **Pages** in your GitHub repository.
2. Under **Build and deployment** > **Source**, select **GitHub Actions**.
3. Every commit to `main` will automatically build and publish the live web app at:
   `https://<your-username>.github.io/<your-repo-name>/`

---

## License

MIT License. Open source and sovereign.
