import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/update_checker_service.dart';

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
            'Hospitality Libre is a pure example of a free, open, decentralized home-sharing network built on the open Nostr protocol. There are no corporate middlemen, no subscription fees, and no centralized databases.\n\nYou own your profile & identity, your references, and your listings. If "Hospitality Libre" gets abandoned by developers, or you just don\'t like the way it works, you can simply move to another app that uses the same network, with your same identity, private message history, and all your information.\n\nSince anyone can build an app that uses the network, you can switch between different apps and interfaces that use the network, choosing whatever has the design and features you like best, without starting from scratch. As a developer, you can focus on building the best experience possible, without worrying about re-building the community and user base.\n\nOther apps, like Trip Hopping, also use the Nostr hospitlity network while offering more robust features you may expect, like meetups, hangouts, community notes, and ridesharing. Other apps will surely emerge with interesting travel and community features as well. "Hospitality Libre," however, serves as a clean and simple example of pure hospitality exchange. It is for hosts and travelers to connect, and for developers to use as a reference for building their own Nostr hospitality apps, and will accordingly reflect any changes in the protocol as it develops and evolves.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Android Distribution & Download Section
          _buildAndroidDownloadSection(context, theme, isDark),
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
            title: 'Hosting Offers & Travel Requests (NIP-99)',
            description:
                'Hosts publish accommodation offers as hospitality-offer, and travelers post date-bound stay requests (Public Trips) as hospitality-request to find local hosts across open relays.',
          ),
          _buildFeatureCard(
            context,
            theme,
            icon: Icons.security_rounded,
            title: 'Geohash Privacy Protection',
            description:
                'Host locations are bounded between 3 to 5 characters (defaulting to ~5km neighborhood box). Your exact street address is strictly protected and never published.',
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

  Widget _buildAndroidDownloadSection(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.android_rounded,
                    color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get the Android App',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '100% Free & Open-Source (FOSS) • No Google Play Required',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hospitality Libre is distributed independently without corporate trackers, Google Play account requirements, or middlemen. Anyone can install the Android APK directly.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'How to Install & Update Outside Google Play:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Tap "Download Android APK" below and open the downloaded file.\n'
                  '2. If Android prompts "Install unknown apps", tap Settings and allow "From this source".\n'
                  '3. Built-in updates: The app checks for protocol updates automatically, or you can manage releases with Obtainium or F-Droid.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://github.com/${UpdateCheckerService.repoOwner}/${UpdateCheckerService.repoName}/releases/latest/download/hospitality-libre-latest.apk'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Android APK'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  launchUrl(
                    Uri.parse(UpdateCheckerService.releasesWebUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View All Releases'),
              ),
            ],
          ),
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
            title:
                'Hospitality Classifieds: Offers & Requests (Kind 30402 - NIP-99)',
            intro:
                'NIP-99 Classified Listing specification for both Hosting Offers and Traveler Stay Requests with 3 to 5 character geohash privacy bounds (defaulting to 5 characters, ~5km neighborhood zone), start/end date tags, and tri-state household preferences (see nips/hospitality-listings.md):',
            jsonSpec: '''{
  "kind": 30402,
  "pubkey": "<author-pubkey-hex>",
  "content": "Visiting Chicago for the architecture biennial and local jazz scene. Looking for a host or coffee meetups near downtown!",
  "tags": [
    ["d", "trip-chicago-20261102"],
    ["title", "Visiting Chicago for Architecture & Jazz"],
    ["summary", "Solo traveler seeking 3 nights in Chicago."],
    ["location", "Chicago, IL, USA"],
    ["g", "d"],
    ["g", "dp"],
    ["g", "dp3"],
    ["g", "dp3w"],
    ["g", "dp3wh"],
    ["origin_lat", "41.8781"],
    ["origin_lon", "-87.6298"],
    ["status", "active"],
    ["published_at", "1719234800"],
    ["t", "hospitality"],
    ["t", "hospitality-request"],
    ["price", "0", "USD"],
    ["start", "1793577600"],
    ["end", "1793836800"],
    ["max_guests", "1"],
    ["pets_allowed", "false"],
    ["wheelchair", "false"]
  ]
}''',
            contentDesc:
                'The content field contains the detailed description of the space or trip itinerary, hosting/travel philosophy, expectations, and logistics.',
            tags: [
              '`d` (REQUIRED) - Addressable listing identifier (e.g. `<pubkey>-home` for offers, `trip-<destination>-<date>` for requests)',
              '`title` (REQUIRED) - Human-readable title of the hosting offer or travel request',
              '`summary` (OPTIONAL) - Short preview text for cards and search feeds',
              '`location` (REQUIRED) - Human-readable location display name (e.g. "Seattle, WA, USA")',
              '`g` (REQUIRED) - Cascading geohash tags bounded between 3 to 5 characters (default 5 characters, e.g. `c`, `c2`, `c23`, `c23n`, `c23nb` ~5km neighborhood area) for privacy protection',
              '`origin_lat` / `origin_lon` (OPTIONAL) - Approximate geohash center coordinate for simple client map pin rendering',
              '`status` (REQUIRED) - `active` (currently accepting guests or open request) or `sold`/`closed` (closed/inactive)',
              '`t` (REQUIRED) - `["t", "hospitality"]`, along with `["t", "hospitality-offer"]` or `["t", "hospitality-request"]`. (Absence of offer/request tag defaults to offer)',
              '`start` / `end` (OPTIONAL) - Unix epoch timestamps for arrival/departure dates or temporary hosting availability window',
              '`price` (OPTIONAL) - Defaults to `["price", "0", "USD"]` for open hospitality',
              '`image` (OPTIONAL) - Direct photo image URLs',
              '`max_guests` - Capacity accommodated (offer) or party size (request)',
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
    ["start", "1718064000"],
    ["end", "1718582400"],
    ["t", "communicative"],
    ["t", "clean"],
    ["t", "inspiring"],
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
              '`start` / `end` (OPTIONAL) - Unix timestamps indicating when the interaction/stay took place in the physical world (NIP-52 convention)',
              '`t` (OPTIONAL) - Arbitrary interaction trait and label hashtags (`["t", "communicative"]`, `["t", "clean"]`, `["t", "prompt"]`)',
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
                'Draft NIP specification for parameterized addressable profile events extending Kind 0 with real-world travel identity, nickname, languages, current mobility, and external verifications (see nips/travel-community-profile.md):',
            jsonSpec: '''{
  "kind": 30602,
  "pubkey": "<user-pubkey-hex>",
  "content": "Slow traveler and photographer passionate about food, cycling, and decentralization.",
  "tags": [
    ["d", "travel-profile"],
    ["name", "NomadAlice"],
    ["gender", "female"],
    ["birth_year", "1995"],
    ["birth_month", "4"],
    ["birth_day", "12"],
    ["origin_country", "DE"],
    ["origin_city", "Munich"],
    ["home_country", "FR"],
    ["home_city", "Lyon"],
    ["current_country", "MX"],
    ["current_city", "Oaxaca"],
    ["g", "9g3w8"],
    ["g", "9g3w"],
    ["g", "9g3"],
    ["occupation", "Photographer"],
    ["education", "Master in Visual Arts"],
    ["language", "de", "native"],
    ["language", "en", "fluent"],
    ["language", "fr", "intermediate"],
    ["t", "meetup"],
    ["t", "cycling"],
    ["t", "hiking"],
    ["image", "https://image.nostr.build/adventure1.jpg"],
    ["image", "https://image.nostr.build/adventure2.jpg"],
    ["network", "triphopping", "alice_nomad"],
    ["network", "couchers", "alice_nomad"],
    ["network", "trustroots", "alice_nomad"],
    ["network", "couchsurfing", "alice.traveler"]
  ]
}''',
            contentDesc:
                'The content field contains the personal travel story, philosophy, background, and expectations.',
            tags: [
              '`d` (REQUIRED) - Addressable profile identifier (defaults to `travel-profile`)',
              '`name` (OPTIONAL) - Preferred traveler name, nickname, or trail name',
              '`image` (OPTIONAL) - Direct photo image URLs of adventures, travels, or lifestyle (1st image is treated as primary/cover photo)',
              '`language` - Spoken languages: `["language", "<code>", "<level>"]` (e.g. `["language", "en", "fluent"]`)',
              '`origin_country` / `origin_city` - Origin hometown & roots (ISO 3166-1 alpha-2 2-letter country code)',
              '`home_country` / `home_city` - Current home base / residence location (ISO 3166-1 alpha-2 2-letter country code)',
              '`current_country` / `current_city` - Active nomad location on the road (ISO 3166-1 alpha-2 2-letter country code)',
              '`g` - Cascading geohash tags bounded to 3-5 characters (~5km neighborhood box) representing active presence',
              '`gender` / `birth_year` / `birth_month` / `birth_day` - Optional self-sovereign demographics (`birth_year` calculates dynamic age)',
              '`occupation` / `education` - Professional background',
              '`t` - Topic, hobby, and activity interests (`#meetup`, `#hiking`, `#cycling`, `#nostr`)',
              '`network` - Linked travel & hospitality community profiles (`["network", "<platform>", "<username>"]`)',
            ],
          ),

          // Kind 0 Profile Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Profile Metadata Event (Kind 0)',
            intro: 'Standard Nostr user profile metadata event (NIP-01):',
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
            jsonSpec:
                '''// Gift Wrap (Kind 1059) -> Seal (Kind 13) -> Rumor (Kind 14)
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
