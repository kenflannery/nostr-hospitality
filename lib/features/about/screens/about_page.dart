import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/discover');
            }
          },
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/branding/discover_banner.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.25),
              errorBuilder: (_, __, ___) =>
                  Container(color: theme.colorScheme.primary),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: const Text(
          'About & Nostr Protocols',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
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
      body: SelectionArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTravelersTab(context, theme, isDark),
            _buildDevelopersTab(context, theme, isDark),
          ],
        ),
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
            'Hospitality Libre is a pure example of a free, open, decentralized home-sharing network built on the open Nostr protocol. There are no corporate middlemen, no subscription fees, and no centralized databases.\n\nYou own your profile & identity, your references, your connections with people, and your listings. Since anyone can build an app that uses the network, you can switch between whichever has the design and features you like best, without "starting over." Even if "Hospitality Libre" gets abandoned by developers, or you just don\'t like the way it works, you can simply move to another app that uses the same network, with your same identity, private message history, references, and all your information. No exporting, importing, or migrating data. It just works, everywhere.\n\nApp developers can focus on building the best experience possible, without worrying about re-building the community and user base.\n\nExisting apps, like Trip Hopping, also use the Nostr hospitality network while offering more robust features you may expect from a community travel site, like meetups, hangouts, community notes, and ridesharing. More apps will surely emerge with interesting travel and community features as well. "Hospitality Libre," however, serves as a clean and simple example of pure hospitality exchange. It is for hosts and travelers to connect, and for developers to use as a reference for building their own Nostr hospitality apps, and will develop and evolve whenever needed.',
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
          _buildFeatureCard(
            context,
            theme,
            icon: Icons.group_outlined,
            title: 'Dual-Sync Follows (Kind 3 & Kind 30000)',
            description:
                'Follow hosts, travelers, and friends. Follows are dual-synchronized to your universal Nostr Contact List (Kind 3) and a dedicated Hospitality Libre Follow Set (Kind 30000) so your connections stay portable across apps.',
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
              '`d` (REQUIRED) - Addressable listing identifier unique slug (e.g. `home-<city>-<id>` for offers, `trip-<destination>-<date>` for requests). Allows hosts to maintain multiple distinct listings across locations.',
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
              '`gender` - Optional demographic identity (birth date & age are managed in Kind 0 via NIP-24)',
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

          // NIP-32 Community Labeling Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Community Labeling & Endorsements (Kind 1985 - NIP-32)',
            intro:
                'NIP-32 standalone trait endorsements, lifestyle vibes, and community advisories without requiring a full stay reference:',
            jsonSpec: '''{
  "kind": 1985,
  "pubkey": "<author-pubkey-hex>",
  "content": "Made a wonderful pasta dish and shared stories about the Pacific Crest Trail.",
  "tags": [
    ["L", "#t"],
    ["l", "great_cook", "#t"],
    ["p", "<subject-pubkey-hex>"]
  ],
  "created_at": 1719234800
}''',
            contentDesc:
                'The content field contains optional context, commentary, or anecdote describing the reason for the trait or boundary label.',
            tags: [
              '`L` (REQUIRED) - Label namespace identifier (standardized to `#t` for hashtag / trait endorsements)',
              '`l` (REQUIRED) - Specific label value and namespace (e.g. `["l", "great_cook", "#t"]` or `["l", "creepy", "#t"]`)',
              '`p` (REQUIRED) - Subject pubkey being endorsed or labeled',
              '`e` (OPTIONAL) - Target event ID if the label pertains to a specific listing or stay request',
            ],
          ),

          // NIP-56 Reporting Spec
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Adversarial Reporting & Moderation (Kind 1984 - NIP-56)',
            intro:
                'Standard decentralized reporting for accounts and listings to satisfy Apple App Store Guideline 1.2 and relay spam filtering:',
            jsonSpec: '''{
  "kind": 1984,
  "pubkey": "<reporter-pubkey-hex>",
  "content": "Bot account posting commercial spam links on home listings.",
  "tags": [
    ["p", "<offender-pubkey-hex>", "spam"]
  ],
  "created_at": 1719234800
}''',
            contentDesc:
                'Optional explanation provided by the reporter detailing the violation.',
            tags: [
              '`p` (OPTIONAL) - Offender pubkey with violation category: `["p", "<pubkey>", "<category>"]`',
              '`e` (OPTIONAL) - Specific event ID being reported: `["e", "<event-id>", "<category>"]`',
              '`Standard Categories` - `spam`, `nudity`, `profanity`, `illegal`, `impersonation`, `other`',
            ],
          ),

          // NIP-51 Mute List & Interest Sets
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Mute Lists & Cautionary Sets (Kind 10000 & 30015 - NIP-51)',
            intro:
                'Cryptographically signed personal blocklists and customizable cautionary tag sets:',
            jsonSpec: '''// Kind 10000: Personal Mute List
{
  "kind": 10000,
  "pubkey": "<user-pubkey-hex>",
  "tags": [
    ["p", "<blocked-pubkey-1>"],
    ["p", "<blocked-pubkey-2>"]
  ]
}

// Kind 30015: Cautionary Tags Set (d: hospitality-cautionary-tags)
{
  "kind": 30015,
  "pubkey": "<user-pubkey-hex>",
  "tags": [
    ["d", "hospitality-cautionary-tags"],
    ["t", "creepy"],
    ["t", "thief"],
    ["t", "unresponsive"]
  ]
}''',
            contentDesc:
                'Mute lists allow clients to drop content from blocked users across the entire Nostr network. Kind 30015 defines the user-customizable list of tags considered cautionary/safety-sensitive in their UI.',
            tags: [
              '`Kind 10000` - Replaceable personal mute list tagging blocked pubkeys with `["p", "<pubkey>"]`',
              '`Kind 30015` - Parameterized replaceable set with identifier `hospitality-cautionary-tags` and `["t", "<tag>"]` items',
            ],
          ),

          // Contact List (Kind 3) & Follow Set (Kind 30000)
          _buildSpecSection(
            context,
            theme,
            isDark,
            title: 'Contact Lists & Follow Sets (Kind 3 - NIP-02 & Kind 30000 - NIP-51)',
            intro:
                'Dual-synchronized follow architecture preserving universal Nostr follows while organizing app-specific travel connections:',
            jsonSpec: '''// Kind 3: Universal NIP-02 Contact List
{
  "kind": 3,
  "pubkey": "<user-pubkey-hex>",
  "content": "",
  "tags": [
    ["p", "<contact-pubkey-1>", "wss://relay.damus.io", "alice"],
    ["p", "<contact-pubkey-2>"]
  ]
}

// Kind 30000: NIP-51 Categorized People Set (d: hospitality-libre-follows)
{
  "kind": 30000,
  "pubkey": "<user-pubkey-hex>",
  "content": "",
  "tags": [
    ["d", "hospitality-libre-follows"],
    ["title", "People I follow on Hospitality Libre"],
    ["description", "Hosts, travelers, and friends followed on Hospitality Libre"],
    ["image", "https://image.nostr.build/654699c88f355dfa49f42f5bf5b163d60d031324b5f5805acb02b508e1153881.jpg"],
    ["p", "<contact-pubkey-1>"],
    ["p", "<contact-pubkey-2>"]
  ]
}''',
            contentDesc:
                'Kind 3 publishes standard Nostr follows for compatibility with social clients (Damus, Primal, Amethyst) using non-destructive merging. Kind 30000 maintains the scoped Hospitality Libre follow set with title, description, and cover image.',
            tags: [
              '`Kind 3 tags` - `["p", "<pubkey>", "<relay-url>", "<petname>"]` per NIP-02',
              '`Kind 30000 d` - Identifier set to `hospitality-libre-follows`',
              '`Kind 30000 title` - Human-readable list title',
              '`Kind 30000 description` - Human-readable list summary',
              '`Kind 30000 image` - Cover artwork for the follow set',
              '`Kind 30000 p` - Pubkey tags for each followed community member',
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
