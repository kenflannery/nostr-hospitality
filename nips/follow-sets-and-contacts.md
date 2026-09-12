# NIP-XX: Dual-Sync Follows: Contact Lists & Hospitality Follow Sets

`draft` `optional`

**Kinds:** `3` (NIP-02), `30000` (NIP-51)  
**Authors:** Hospitality Libre Community  

---

## Abstract

This specification defines the dual-synchronization follow architecture for Hospitality Libre. To ensure maximum interoperability across the Nostr ecosystem while maintaining an organized, domain-specific directory of travel connections, follows are maintained across two distinct event kinds:

1. **Universal Contact List (`kind: 3` - NIP-02)**: Enables universal discovery and social feed compatibility across general Nostr clients (Damus, Primal, Amethyst, Coracle).
2. **Categorized People List / Follow Set (`kind: 30000` - NIP-51)**: Maintains a dedicated, scoped follow list specifically for Hospitality Libre connections (`d: hospitality-libre-follows`) complete with human-readable title, description, and list artwork.

---

## The Non-Destructive Merging Rule (CRITICAL)

Because `kind: 3` is a single replaceable event per pubkey, writing a follow list naively would overwrite follows, relay lists, and petnames established in other Nostr clients.

Clients implementing this specification **MUST** follow these rules:
1. **Query Existing Contact List**: Prior to publishing an updated `kind: 3`, the client queries the author's latest `kind: 3` event from connected relays.
2. **Preserve Unmanaged Tags**: All non-`p` tags and existing `p` tags with third-party relay URLs or petnames must be preserved.
3. **Additive Follow**: When following user `X`, if `X` is already present, no duplicate tag is added. If not present, `["p", "<X-pubkey-hex>"]` is appended.
4. **Selective Unfollow**: When unfollowing user `X`, only the `p` tag matching `X` is removed; all other contacts are preserved.

---

## Event Schemas

### 1. Universal Contact List (`kind: 3` - NIP-02)

```json
{
  "kind": 3,
  "pubkey": "<user-pubkey-hex>",
  "content": "",
  "tags": [
    ["p", "<pubkey-hex-1>", "wss://relay.damus.io", "alice"],
    ["p", "<pubkey-hex-2>"]
  ],
  "created_at": 1719234800
}
```

- Each contact is represented by a `p` tag: `["p", "<pubkey>", "<relay-url>", "<petname>"]`.
- Trailing relay URL and petname fields are optional.

---

### 2. Categorized Follow Set (`kind: 30000` - NIP-51)

Follows within Hospitality Libre are grouped into a parameterized replaceable event (`kind: 30000`):

```json
{
  "kind": 30000,
  "pubkey": "<user-pubkey-hex>",
  "content": "",
  "tags": [
    ["d", "hospitality-libre-follows"],
    ["title", "People I follow on Hospitality Libre"],
    ["description", "Hosts, travelers, and friends followed on Hospitality Libre"],
    ["image", "https://image.nostr.build/654699c88f355dfa49f42f5bf5b163d60d031324b5f5805acb02b508e1153881.jpg"],
    ["p", "<followed-pubkey-hex-1>"],
    ["p", "<followed-pubkey-hex-2>"]
  ],
  "created_at": 1719234800
}
```

#### Tags

- `d` (REQUIRED): Set identifier. For Hospitality Libre connections, this value is fixed to `hospitality-libre-follows`.
- `title` (OPTIONAL): Human-readable title: `"People I follow on Hospitality Libre"`.
- `description` (OPTIONAL): Short summary: `"Hosts, travelers, and friends followed on Hospitality Libre"`.
- `image` (OPTIONAL): Direct URL to follow set banner or avatar artwork.
- `p` (REQUIRED for each contact): Hex pubkey of each followed host or traveler: `["p", "<pubkey-hex>"]`.

---

## Client Synchronization Behavior

- **Optimistic Local Update**: UI reflects follow/following state immediately in memory and in local cache (`following_pubkeys`).
- **Concurrent Broadcast**: Broadcasts both `kind: 3` and `kind: 30000` to all configured bootstrap and outbox relays.
- **Background Sync**: On application startup or user login, clients query both kinds from relays to merge newly discovered remote follows into the local cache.
