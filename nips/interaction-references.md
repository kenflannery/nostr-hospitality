# NIP-XX: Interaction References

`draft` `optional`

**Kind:** `7654`  
**Authors:** Hospitality Libre Community  

---

## Abstract

This NIP defines a regular, non-replaceable Nostr event (`kind: 7654`) for publishing a personal reference or review about another user based on a real-world interaction, transaction, service, hospitality exchange, or online collaboration.

References provide a portable, sovereign reputation system that travels with users across any client or relay in the decentralized Nostr ecosystem.

---

## The Reference Event (Kind 7654)

References use kind `7654`.

The event **MUST** contain a single primary `p` tag identifying the user being referenced (the subject).
The event's `.content` contains the free-form reference statement written by the author.

### Example Payload
```json
{
  "kind": 7654,
  "pubkey": "<author-pubkey-hex>",
  "content": "Bob was an exceptional host. He made me feel at home immediately, cooked great dinners, and showed me the local mountain trails.",
  "tags": [
    ["p", "<subject-pubkey-hex>"],
    ["context", "hospitality"],
    ["role", "guest"],
    ["sentiment", "positive"],
    ["t", "communicative"],
    ["t", "clean"],
    ["t", "great_cook"],
    ["a", "30402:<host-pubkey-hex>:<listing-d-tag>"]
  ],
  "created_at": 1719234800
}
```

---

## Tags

### `p` (REQUIRED)
The `p` tag identifies the subject of the reference:
```json
["p", "<subject-pubkey-hex>"]
```
- A reference **MUST** contain exactly one primary `p` tag.
- The author of the event is the reviewer; the `p` tag is the person being reviewed.

### `context` (OPTIONAL)
The `context` tag describes the nature of the interaction:
```json
["context", "hospitality"]
```
Defined standard values:
- `hospitality` — Hosting or guest stay arrangement
- `meeting` — In-person meetup, coffee, city hangout, or social encounter
- `travel` — Traveling together or trip companionship
- `transaction` — Purchase, sale, trade, or peer-to-peer exchange
- `service` — Provided or received a service
- `work_exchange` — Volunteer or work-exchange arrangement
- `other` — Interaction outside predefined categories

### `role` (OPTIONAL)
The `role` tag identifies the **author's role** in the interaction:
```json
["role", "guest"]
```
Common defined roles:
- `host` (author was the host $\rightarrow$ subject was the guest)
- `guest` (author was the guest $\rightarrow$ subject was the host)
- `traveler` / `travel_companion`
- `buyer` / `seller`
- `provider` / `customer`
- `other`

### `sentiment` (OPTIONAL)
The `sentiment` tag provides a coarse classification:
```json
["sentiment", "positive"]
```
Allowed values:
- `positive`
- `neutral`
- `negative`

> **CRITICAL RULE ON SENTIMENT NULLABILITY**:  
### `t` (OPTIONAL)
Arbitrary trait, label, or topic hashtags describing specific qualities or observations from the interaction:
```json
["t", "communicative"],
["t", "inspiring"],
["t", "clean"],
["t", "respectful"],
["t", "prompt"]
```

### `a` and `e` (OPTIONAL)
- `a`: Addressable coordinate referencing an associated listing or object (e.g. `["a", "30402:<pubkey>:<d-tag>"]`).
- `e`: Event ID of a specific immutable event tied to the interaction.

---

## Client Presentation & Reputation Aggregation

Clients **SHOULD NOT** aggregate references into arbitrary five-star ratings or proprietary decimal scores.

Instead, clients **SHOULD** present objective, factual summaries:
- **Total References** received by the user
- **Sentiment Breakdown**: Number of positive, neutral, negative, and unspecified statements
- **Role Breakdown**: Number of references written by hosts vs. guests
- Chronological list of verbatim reference statements with author avatars, names, and timestamps
