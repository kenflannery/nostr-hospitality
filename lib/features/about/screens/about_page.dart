import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive developer & traveler reference guide for Hospitality Libre.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Nostr Protocols'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(
              icon: Icon(Icons.travel_explore_rounded),
              text: 'For Travelers',
            ),
            Tab(
              icon: Icon(Icons.code_rounded),
              text: 'For Developers',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTravelersTab(context, theme, isDark),
          _buildDevelopersTab(context, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildTravelersTab(
      BuildContext context, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '100% Nostr-Native Hospitality',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hospitality Libre is a free, open, decentralized home-sharing network built on the open Nostr protocol. There are no corporate middlemen, no subscription fees, and no centralized databases.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          _buildFeatureCard(
            context,
            theme,
            icon: Icons.key_rounded,
            title: 'Sovereign Cryptographic Identity',
            description:
                'You own your identity with cryptographic keys (npub/nsec). No corporation can ban, censor, or lock you out of your travel profile.',
          ),
          _buildFeatureCard(
            context,
            theme,
            icon: Icons.home_work_outlined,
            title: 'Open Hosting Offers (NIP-99)',
            description:
                'Hosts publish accommodation offers (couches, private rooms, house swaps) as NIP-99 classified events across open relays.',
          ),
          _buildFeatureCard(
            context,
            theme,
            icon: Icons.security_rounded,
            title: 'Geohash Privacy Protection',
            description:
                'Host locations are strictly bounded to a 4-character geohash (~20-40km area). Your exact home address is never exposed on the public network.',
          ),
          _buildFeatureCard(
            context,
            theme,
            icon: Icons.rate_review_outlined,
            title: 'Portable Interaction References (Kind 7654)',
            description:
                'References are signed historical statements between hosts and guests. Your reputation travels with you across every app in the Nostr ecosystem.',
          ),
          _buildFeatureCard(
            context,
            theme,
            icon: Icons.lock_outline_rounded,
            title: 'Private Messaging (NIP-17)',
            description:
                'Coordinate stays with end-to-end encrypted direct messages using NIP-17 gift-wrapping. Only you and your recipient can read them.',
          ),

          const SizedBox(height: 28),
          Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),

          Text(
            'Understanding Keypairs',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Public Key (npub): Your public travel identity. Share this freely with other hosts and travelers.\n'
            '• Private Key (nsec): Your secret signing key. Never share this with anyone! It is saved securely on your device.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopersTab(
      BuildContext context, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol Specifications & Interoperability',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hospitality Libre defines the open standard for decentralized hospitality, home sharing, and interpersonal references on Nostr. Align queries and broadcasts with these specifications to build interoperable clients.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),

          // General Relay & Architecture Card
          Card(
            margin: const EdgeInsets.only(bottom: 24.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Relays & Cryptographic Signers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bootstrap Relays:',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• wss://relay.damus.io\n'
                    '• wss://nos.lol\n'
                    '• wss://relay.primal.net\n'
                    '• wss://relay.nostr.band\n'
                    '• wss://relay.trustroots.org',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Key Management & Signatures:',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Private keys (nsec) are stored locally in platform secure storage. Event signatures conform to standard BIP-340 Schnorr signatures.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Kind 30402 Classified Hospitality Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Hospitality Hosting Offer (Kind 30402 - NIP-99 Profile)',
            intro:
                'NIP-99 Classified Listing profile for hospitality accommodation (couch, private room, shared room, tent space) with 4-character geohash privacy bounds and tri-state household preferences (see nips/hospitality-listings.md):',
            jsonSpec: '''{
  "kind": 30402,
  "pubkey": "<host-pubkey-hex>",
  "content": "Hosting travelers in Seattle! We have a private guest room with queen bed and shared bath. Love showing travelers around town, sharing meals, and talking about open protocols.",
  "tags": [
    ["d", "<host-pubkey-hex>-home"],
    ["title", "Cozy guest room in Seattle, WA"],
    ["summary", "Private guest room with queen bed near downtown Seattle"],
    ["location", "Seattle, WA, USA"],
    ["g", "c"],
    ["g", "c2"],
    ["g", "c23"],
    ["g", "c23n"],
    ["origin_lat", "47.6062"],
    ["origin_lon", "-122.3321"],
    ["status", "active"],
    ["published_at", "1719234800"],
    ["t", "hospitality"],
    ["t", "Home"],
    ["price", "0", "USD"],
    ["image", "https://example.com/room.jpg"],

    // Hosting Preferences
    ["max_guests", "2"],
    ["last_minute", "true"],
    ["wheelchair", "false"],
    ["tent_camping", "false"],
    ["kids_allowed", "true"],
    ["pets_allowed", "false"],
    ["drinking_allowed", "true"],
    ["smoking_allowed", "outside"],

    // My Home & Environment
    ["sleeping_arrangement", "private_room"],
    ["parking", "street"],
    ["parking_details", "Free street parking after 6 PM"],
    ["has_housemates", "false"],
    ["has_kids", "false"],
    ["has_pets", "true"],
    ["host_drinks", "true"],
    ["host_smokes", "no"]
  ]
}''',
            contentDesc:
                'The content field contains the detailed description of the space, hosting philosophy, house expectations, and check-in details.',
            tags: [
              '`d` (REQUIRED) - Addressable listing identifier (e.g. `<pubkey>-home`)',
              '`title` (REQUIRED) - Human-readable title of the hosting offer',
              '`summary` (OPTIONAL) - Short preview text for cards and search feeds',
              '`location` (REQUIRED) - Human-readable location display name (e.g. "Seattle, WA, USA")',
              '`g` (REQUIRED) - Cascading geohash tags strictly truncated to 4 characters (`c`, `c2`, `c23`, `c23n` ~20-40km area) for host privacy protection',
              '`origin_lat` / `origin_lon` (OPTIONAL) - Approximate geohash center coordinate for simple client map pin rendering',
              '`status` (REQUIRED) - `active` (currently accepting guests) or `sold` (closed/inactive)',
              '`t` (REQUIRED) - `hospitality` (identifies hospitality listings) and `Home` (NIP-99 top-level category)',
              '`price` (OPTIONAL) - Defaults to `["price", "0", "USD"]` for open hospitality',
              '`image` (OPTIONAL) - Direct photo image URLs of the accommodation',
              '`max_guests` - Maximum number of travelers hosted simultaneously (e.g. "2")',
              '`last_minute` - `"true"` / `"false"` (open to same-day requests)',
              '`wheelchair` - `"true"` / `"false"` (wheelchair accessible)',
              '`tent_camping` - `"true"` / `"false"` (yard/lawn space available for tents)',
              '`kids_allowed` / `pets_allowed` - `"true"` / `"false"`',
              '`drinking_allowed` - `"true"` / `"false"`',
              '`smoking_allowed` - `"no"` / `"outside"` / `"yes"`',
              '`sleeping_arrangement` - `"private_room"` / `"shared_room"` / `"couch"` / `"common_room"` / `"tent_space"`',
              '`parking` - `"none"` / `"free_on_premises"` / `"street"` / `"paid"`',
              '`parking_details` - Optional human-readable parking instructions',
              '`has_housemates` / `has_kids` / `has_pets` - `"true"` / `"false"`',
              '`host_drinks` - `"true"` / `"false"`',
              '`host_smokes` - `"no"` / `"outside"` / `"yes"`',
            ],
          ),

          // Kind 7654 Reference Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Interaction References (Kind 7654 - Draft NIP)',
            intro:
                'Draft NIP specification for historical, non-replaceable statements by one user about another user based on a real-world interaction (see nips/interaction-references.md):',
            jsonSpec: '''{
  "kind": 7654,
  "pubkey": "<author-pubkey-hex>",
  "content": "Bob was an exceptional host! He showed me around town, cooked great meals, and made me feel completely at home.",
  "tags": [
    ["p", "<subject-pubkey-hex>"],
    ["context", "hospitality"],
    ["role", "guest"],
    ["sentiment", "positive"],
    ["a", "30402:<host-pubkey-hex>:<listing-d-tag>"]
  ]
}''',
            contentDesc:
                'The content field contains the free-form reference statement written by the author.',
            tags: [
              '`p` (REQUIRED) - Exactly one pubkey tag identifying the user being referenced',
              '`context` (OPTIONAL) - Nature of interaction: `hospitality`, `meeting`, `travel`, `transaction`, `service`, `work_exchange`, `other` (default: `hospitality`)',
              '`role` (OPTIONAL) - Author\'s role: `host`, `guest`, `traveler`, `buyer`, `seller`, `customer`, `provider`, `other`',
              '`sentiment` (OPTIONAL) - Coarse assessment: `positive`, `neutral`, `negative`. NOTE: Absence of sentiment MUST remain null and NOT defaulted to neutral',
              '`a` (OPTIONAL) - Addressable coordinate of associated object (e.g. `30402:<pubkey>:<d-tag>`)',
              '`e` (OPTIONAL) - Event ID of a specific immutable event associated with the interaction',
            ],
          ),

          // Kind 30602 Travel & Community Profile Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Travel & Community Profile (Kind 30602 - Draft NIP)',
            intro:
                'Draft NIP specification for parameterized addressable profile events extending Kind 0 with real-world travel identity, languages, interaction modes, and external verifications (see nips/travel-community-profile.md):',
            jsonSpec: '''{
  "kind": 30602,
  "pubkey": "<user-pubkey-hex>",
  "content": "Slow traveler and photographer passionate about food, cycling, and decentralization.",
  "tags": [
    ["d", "travel-profile"],
    ["gender", "female"],
    ["birth_year", "1995"],
    ["origin_country", "DE"],
    ["origin_city", "Munich"],
    ["home_country", "FR"],
    ["home_city", "Lyon"],
    ["occupation", "Photographer"],
    ["education", "Master in Visual Arts"],
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
    ["i", "triphopping:alice_nomad"],
    ["i", "couchers:alice_nomad"],
    ["i", "trustroots:alice_nomad"],
    ["i", "couchsurfing:alice.traveler"]
  ]
}''',
            contentDesc:
                'The content field contains the personal travel story, philosophy, background, and expectations.',
            tags: [
              '`d` (REQUIRED) - Addressable profile identifier (defaults to `travel-profile`)',
              '`image` (OPTIONAL) - Direct photo image URLs of adventures, travels, or lifestyle hosted on decentralized media servers',
              '`mode` - Active interaction modes: `host`, `guest`, `meetup`, `rideshare`, `language_exchange`',
              '`language` - Spoken languages: `["language", "<code>", "<level>"]` (e.g. `["language", "en", "fluent"]`)',
              '`origin_country` / `origin_city` - Where the user grew up / origin location',
              '`home_country` / `home_city` - Current home base / residence location',
              '`gender` / `birth_year` - Optional self-sovereign demographics (`birth_year` allows dynamic age computation)',
              '`occupation` / `education` - Professional background',
              '`t` - Topic and hobby interests (`#hiking`, `#cycling`, `#nostr`)',
              '`i` - NIP-39 style external identity links (e.g. `["i", "triphopping:alice"]`, `["i", "couchers:alice"]`, `["i", "trustroots:alice"]`)',
            ],
          ),

          // Kind 0 Profile Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Profile Metadata Event (Kind 0)',
            intro:
                'Standard Nostr user profile metadata event (NIP-01):',
            jsonSpec: '''{
  "kind": 0,
  "content": "{\\"name\\": \\"alice\\", \\"display_name\\": \\"Alice Traveler\\", \\"about\\": \\"Slow travel and hiking enthusiast\\", \\"nip05\\": \\"alice@example.com\\"}",
  "tags": []
}''',
            contentDesc:
                'JSON stringified dictionary containing standard profile fields. Existing unmanaged fields are preserved on edit.',
            tags: [
              '`name` / `display_name` - Username and display name',
              '`about` - Bio / traveler intro',
              '`picture` / `banner` - Avatar and header image URLs',
              '`nip05` - DNS internet identifier for verification',
              '`website` - Personal website URL',
            ],
          ),

          // NIP-17 Direct Messaging Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Private Messaging (NIP-17)',
            intro:
                'End-to-end encrypted private direct messaging with gift wrapping (NIP-59 / NIP-17):',
            jsonSpec: '''// Gift Wrap (Kind 1059) -> Seal (Kind 13) -> Rumor (Kind 14)
{
  "kind": 1059,
  "content": "<nip44-encrypted-seal>",
  "tags": [
    ["p", "<recipient-pubkey>"]
  ]
}''',
            contentDesc:
                'Private direct messages are wrapped in ephemeral keys so relays cannot determine the true sender or message content.',
            tags: [
              '`Kind 1059` - Gift Wrap containing recipient pubkey and encrypted seal',
              '`Kind 13` - Seal signed by the sender containing encrypted rumor',
              '`Kind 14` - Rumor containing the plaintext private message and timestamp',
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSpecSection(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required String title,
    required String intro,
    required String jsonSpec,
    required String contentDesc,
    required List<String> tags,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              intro,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildCodeBlock(context, theme, isDark, jsonSpec),
            const SizedBox(height: 16),
            Text(
              'Content',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              contentDesc,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Tags / Schema',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...tags.map(
              (tag) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        tag,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBlock(
      BuildContext context, ThemeData theme, bool isDark, String json) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2421) : const Color(0xFFEAEFEA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 48, 12),
            child: SelectableText(
              json,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy Code Block',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: json));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Spec copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
