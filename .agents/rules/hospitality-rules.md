---
trigger: always_on
---

# Hospitality Libre Architecture & Development Rules

Hospitality Libre is a 100% Nostr-native, decentralized hospitality, travel community, and interpersonal reputation application built with Flutter, feature-first, clean architecture.

---

## 1. The 4-Way Protocol Synchronization Rule (CRITICAL)

Whenever any Nostr Event Kind, tag name, allowed value, or protocol structure is added, modified, or refined, the following four locations **MUST ALWAYS BE UPDATED IN SYNC**:

1. **In-App Developer Guide**: `lib/features/about/screens/about_page.dart` (JSON schema examples and tag descriptions for travelers & developers).
2. **Repository Documentation**: `README.md` (protocol overview tables, tag lists, and specification links).
3. **Formal NIP Specifications**: Markdown documents in `nips/`:
   - `nips/hospitality-listings.md` (Kind 30402)
   - `nips/travel-community-profile.md` (Kind 30602)
   - `nips/interaction-references.md` (Kind 7654)
4. **Code Models, Repositories, & Tests**:
   - `lib/models/*.dart` (`HospitalityListing`, `TravelProfile`, `InteractionReference`, `UserProfile`, `ChatMessage`)
   - `lib/core/constants/nostr_constants.dart`
   - `test/models/*_test.dart` and `test/repositories/*_test.dart`

---

## 2. Nostr Event Kinds & Schema Rules

### Kind 0: Standard Profile Metadata (NIP-01)
- Standard user metadata (name, display name, about, picture, banner, nip05, website, lud16).
- **Safe Editing**: Updates must merge existing JSON fields from relay profiles, never clobbering unmanaged third-party fields.

### Kind 30402: Hospitality Classified Listing (NIP-99)
- Parameterized addressable event (`d: <pubkey>-home`).
- Topics: `["t", "hospitality"]` and `["t", "Home"]`.
- **Geohash Privacy**: Host and traveler street addresses are strictly protected by bounding `g` tags between **3 to 5 characters** (defaulting to 5 characters `~5km` neighborhood area; 4 characters `~20-40km` city area; 3 characters `~150km` regional area). Exact street coordinates are NEVER published to relays. `origin_lat`/`origin_lon` represent the geohash bounding box center.
- **Tri-State Preference Tags**: Standard tags (`max_guests`, `last_minute`, `wheelchair`, `tent_camping`, `kids_allowed`, `pets_allowed`, `drinking_allowed`, `smoking_allowed`, `sleeping_arrangement`, `parking`, `has_housemates`, `has_kids`, `has_pets`, `host_drinks`, `host_smokes`). Absence of tag = unspecified; `"true"` = yes; `"false"` = no.

### Kind 30602: Travel & Community Profile (Draft NIP)
- Parameterized addressable event (`d: travel-profile`).
- Isolates travel domains from Kind 0 so social clients don't overwrite them.
- Tags: `name` (preferred traveler name/nickname/trail name), `language` (code, proficiency level), `origin_country`/`origin_city`, `home_country`/`home_city`, `current_country`/`current_city` (ISO 3166-1 alpha-2 uppercase country codes), `g` (cascading geohashes 3-5 chars for active presence location), `gender`, `birth_year`/`birth_month`/`birth_day` (allows dynamic age calculation), `occupation`, `education`, `t` (interests/hobbies/activities), `image` (travel photos), `network` (NIP-39 linked accounts: couchsurfing, trustroots, couchers, bewelcome, warmup, etc.).

### Kind 7654: Interaction References (Draft NIP)
- Regular, historical, non-replaceable event.
- Core Tags:
  - `p` (REQUIRED): Exactly one pubkey tag identifying the subject being reviewed.
  - `context` (OPTIONAL): `hospitality`, `meeting`, `travel`, `transaction`, `service`, `work_exchange`, `other` (default: `hospitality`).
  - `role` (OPTIONAL): Author's role (`host`, `guest`, `traveler`, `buyer`, `seller`, `customer`, `provider`, `other`).
  - `sentiment` (OPTIONAL): `positive`, `neutral`, `negative`. **CRITICAL RULE**: Absence of sentiment MUST remain `null` and NEVER default or coerce into `"neutral"`.
  - `start` / `end` (OPTIONAL): Unix timestamps for when the physical stay or encounter took place (NIP-52 convention). Single encounter uses `start` only; multi-day stay uses both `start` and `end`.
  - `t` (OPTIONAL): Trait and quality hashtags (`communicative`, `clean`, `inspiring`, `respectful`, `prompt`, `great_cook`).
  - `a` / `e` (OPTIONAL): Coordinate of linked listing (`30402:<pubkey>:<d-tag>`) or event ID.
- **Reputation Aggregation**: Clients MUST display objective factual breakdowns (subtotals of positive/neutral/negative and host/guest counts) without arbitrary decimal averages or 5-star scoring algorithms.

### Kind 1059 / 13 / 14: Private Direct Messaging (NIP-17 / NIP-59)
- End-to-end encrypted direct messaging using Gift Wrapping (`kind: 1059`), Seal (`kind: 13`), and Rumor (`kind: 14`).
- Wrapped using NIP-44 v2 encryption.

---

## 3. Cryptographic Signers & Authentication Invariants

1. **Local Keys (`nsec` / hex)**:
   - Handled via `SecureLocalSignerService` + `Bip340EventSigner`. Private keys stored encrypted in device secure storage.
2. **NIP-07 Web Extensions**:
   - Direct JS interop via `window.nostr`.
   - **NIP-44 Requirement for DMs**: If `window.nostr.nip44` is unsupported by the user's extension (e.g. nos2x), the app provides a warning with a recommendation link to Soapbox Signer or Amber/nsec login.
3. **NIP-46 Remote Signers / Amber (Android & Web)**:
   - **Client Transport Private Key**: MUST preserve `&client=<clientPrivateKeyHex>` in stored bunker URIs so Amber recognizes the authorized client public key across app sessions.
   - **Multi-Relay Bunker Connectivity**: `BunkerConnection` must listen on ALL application relays (`relayConfig.relays`), not just a single URL.
   - **Pacing & Serialization**: Remote calls to Amber must use sequential async queueing with ~180ms delay pacing to avoid relay rate-limiting (`"rate-limited: you are noting too much"`).
   - **Timeout Protection**: All remote NIP-46 calls (`decryptNip44`, `sign`, `encryptNip44`) must include per-call timeouts (6-8s) and try-catch handling so a dropped packet never hangs the message loader or UI indefinitely.
   - **Non-Blocking Login**: `loginWithNip46` must dismiss the login dialog immediately and not block on background relay list signing (`publishRelayLists()`).

---

## 4. Relay Management & Message Fallbacks

- Default bootstrap relays:
  - `wss://relay.damus.io`
  - `wss://nos.lol`
  - `wss://relay.primal.net`
  - `wss://relay.nostr.band`
  - `wss://relay.trustroots.org`
- If an account has never published Kind 10050 DM relays, seed fallback relay lists into NDK cache (`ensureUserRelayListInCache`) to prevent lookup crashes.
- Direct query fallback queries `Kind 1059` events from configured relays and parses via `ndk.dms.parseWrappedMessage`.