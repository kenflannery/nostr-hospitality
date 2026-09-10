import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/nip19_utils.dart';
import '../../repositories/listing_repository.dart';
import '../../models/hospitality_listing.dart';
import '../../models/user_profile.dart';
import '../../models/travel_profile.dart';
import '../../features/about/screens/about_page.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/traveler_onboarding_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/listing_editor_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/travel_profile_editor_screen.dart';
import '../../features/references/screens/reference_composer_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../main.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central GoRouter configuration with custom semantic URLs and deep links.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/discover',
    debugLogDiagnostics: false,
    routes: [
      // Stateful shell for persistent bottom tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Discover & Filtered Views (All, Offers/Hosts, Requests/Travelers)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                redirect: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  if (tab == 'offers') return '/offers';
                  if (tab == 'requests') return '/requests';
                  return null;
                },
                builder: (context, state) =>
                    const DiscoverScreen(initialTypeFilter: ListingTypeFilter.all),
              ),
              GoRoute(
                path: '/offers',
                builder: (context, state) =>
                    const DiscoverScreen(initialTypeFilter: ListingTypeFilter.offersOnly),
              ),
              GoRoute(
                path: '/requests',
                builder: (context, state) =>
                    const DiscoverScreen(initialTypeFilter: ListingTypeFilter.requestsOnly),
              ),
            ],
          ),
          // Branch 1: Messages / Conversations
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const ConversationsScreen(),
              ),
            ],
          ),
          // Branch 2: Current User Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Top-level shortcuts / redirects
      GoRoute(
        path: '/',
        redirect: (context, state) => '/discover',
      ),

      // Detailed Listings: /listings/:author/:dTag or /offers/:author/:dTag or /requests/:author/:dTag
      GoRoute(
        path: '/listings/:author/:dTag',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final author = state.pathParameters['author'] ?? '';
          final dTag = state.pathParameters['dTag'] ?? '';
          final listing = state.extra is HospitalityListing
              ? state.extra as HospitalityListing
              : null;
          return ListingDetailScreen(
            listing: listing,
            authorPubkey: author,
            dTag: dTag,
          );
        },
      ),
      GoRoute(
        path: '/offers/:author/:dTag',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final author = state.pathParameters['author'] ?? '';
          final dTag = state.pathParameters['dTag'] ?? '';
          final listing = state.extra is HospitalityListing
              ? state.extra as HospitalityListing
              : null;
          return ListingDetailScreen(
            listing: listing,
            authorPubkey: author,
            dTag: dTag,
          );
        },
      ),
      GoRoute(
        path: '/requests/:author/:dTag',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final author = state.pathParameters['author'] ?? '';
          final dTag = state.pathParameters['dTag'] ?? '';
          final listing = state.extra is HospitalityListing
              ? state.extra as HospitalityListing
              : null;
          return ListingDetailScreen(
            listing: listing,
            authorPubkey: author,
            dTag: dTag,
          );
        },
      ),
      GoRoute(
        path: '/c/:coordinate',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final coordinate = state.pathParameters['coordinate'] ?? '';
          final listing = state.extra is HospitalityListing
              ? state.extra as HospitalityListing
              : null;
          return ListingDetailScreen(
            listing: listing,
            coordinate: coordinate,
          );
        },
      ),

      // Profile Editors (must precede /profile/:pubkey to avoid greedy parameter match)
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final profile =
              state.extra is UserProfile ? state.extra as UserProfile : null;
          return EditProfileScreen(currentProfile: profile);
        },
      ),
      GoRoute(
        path: '/profile/travel-edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final travel =
              state.extra is TravelProfile ? state.extra as TravelProfile : null;
          return TravelProfileEditorScreen(initialProfile: travel);
        },
      ),

      // User Profiles: /p/:pubkey or /profile/:pubkey (supports npub or hex)
      GoRoute(
        path: '/p/:pubkey',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final pubkey = state.pathParameters['pubkey'];
          return ProfileScreen(pubkey: pubkey);
        },
      ),
      GoRoute(
        path: '/profile/:pubkey',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final pubkey = state.pathParameters['pubkey'];
          return ProfileScreen(pubkey: pubkey);
        },
      ),

      // Direct Messaging: /messages/:pubkey or /chat/:pubkey
      GoRoute(
        path: '/messages/:pubkey',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final pubkey = state.pathParameters['pubkey'] ?? '';
          final name = state.uri.queryParameters['name'];
          return ChatScreen(
            recipientPubkey: pubkey,
            recipientName: name,
          );
        },
      ),
      GoRoute(
        path: '/chat/:pubkey',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final pubkey = state.pathParameters['pubkey'] ?? '';
          final name = state.uri.queryParameters['name'];
          return ChatScreen(
            recipientPubkey: pubkey,
            recipientName: name,
          );
        },
      ),

      // Create / Edit Listings
      GoRoute(
        path: '/offers/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ListingEditorScreen(
          initialIsRequest: false,
        ),
      ),
      GoRoute(
        path: '/requests/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ListingEditorScreen(
          initialIsRequest: true,
        ),
      ),
      GoRoute(
        path: '/listings/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final isRequest = state.uri.queryParameters['type'] == 'request';
          return ListingEditorScreen(initialIsRequest: isRequest);
        },
      ),
      GoRoute(
        path: '/listings/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final listing = state.extra is HospitalityListing
              ? state.extra as HospitalityListing
              : null;
          return ListingEditorScreen(initialListing: listing);
        },
      ),

      // References
      GoRoute(
        path: '/references/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final subject = state.uri.queryParameters['subject'] ?? '';
          final name = state.uri.queryParameters['name'];
          final listing = state.extra is HospitalityListing
              ? state.extra as HospitalityListing
              : null;
          return ReferenceComposerScreen(
            subjectPubkey: subject,
            subjectName: name,
            initialListing: listing,
          );
        },
      ),

      // Settings, About, Auth
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TravelerOnboardingScreen(),
      ),
    ],

    // 404 Not Found Screen
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 72,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.uri.path}" could not be found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/discover'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go to Discover'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // --- Type-safe Navigation Helpers ---

  static void toProfile(BuildContext context, String pubkey) {
    final npub = Nip19Helper.pubkeyToNpub(pubkey);
    context.go('/p/$npub');
  }

  static void toListing(BuildContext context, HospitalityListing listing) {
    final authorNpub = Nip19Helper.pubkeyToNpub(listing.authorPubkey);
    final prefix = listing.isRequest ? 'requests' : 'offers';
    context.go('/$prefix/$authorNpub/${listing.dTag}', extra: listing);
  }

  static void toChat(BuildContext context, String pubkey, {String? name}) {
    final npub = Nip19Helper.pubkeyToNpub(pubkey);
    final query = name != null ? '?name=${Uri.encodeComponent(name)}' : '';
    context.go('/messages/$npub$query');
  }

  static void toSettings(BuildContext context) {
    context.go('/settings');
  }

  static void toAbout(BuildContext context) {
    context.go('/about');
  }

  static void toLogin(BuildContext context) {
    context.go('/login');
  }

  static void toOnboarding(BuildContext context) {
    context.go('/onboarding');
  }

  static void toNewOffer(BuildContext context) {
    context.go('/offers/new');
  }

  static void toNewRequest(BuildContext context) {
    context.go('/requests/new');
  }

  static void toEditListing(BuildContext context, HospitalityListing listing) {
    context.go('/listings/edit', extra: listing);
  }

  static void toDiscover(BuildContext context) {
    context.go('/discover');
  }

  static void toEditProfile(BuildContext context, [UserProfile? profile]) {
    context.go('/profile/edit', extra: profile);
  }

  static void toEditTravelProfile(BuildContext context, [TravelProfile? profile]) {
    context.go('/profile/travel-edit', extra: profile);
  }

  static void toNewReference(
    BuildContext context, {
    required String subjectPubkey,
    String? subjectName,
    HospitalityListing? initialListing,
  }) {
    final npub = Nip19Helper.pubkeyToNpub(subjectPubkey);
    final nameParam =
        subjectName != null ? '&name=${Uri.encodeComponent(subjectName)}' : '';
    context.go(
      '/references/new?subject=$npub$nameParam',
      extra: initialListing,
    );
  }
}
