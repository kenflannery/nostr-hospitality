import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr_hospitality/core/navigation/app_router.dart';
import 'package:nostr_hospitality/core/nostr/relay_config.dart';
import 'package:nostr_hospitality/core/providers/app_providers.dart';
import 'package:nostr_hospitality/core/utils/nip19_utils.dart';
import 'package:nostr_hospitality/main.dart';

void main() {
  const testHexPubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  final testNpub = Nip19Helper.pubkeyToNpub(testHexPubkey);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppRouter.router.go('/discover');
  });

  group('AppRouter Route Configuration Tests', () {
    test('Router initialLocation is /discover', () {
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/discover');
    });

    test('Parses /p/:pubkey with npub correctly', () {
      final route = AppRouter.router.configuration.findMatch(Uri.parse('/p/$testNpub'));
      expect(route.matches, isNotEmpty);
      expect(route.pathParameters['pubkey'], testNpub);
    });

    test('Parses /profile/:pubkey with hex correctly', () {
      final route = AppRouter.router.configuration.findMatch(Uri.parse('/profile/$testHexPubkey'));
      expect(route.matches, isNotEmpty);
      expect(route.pathParameters['pubkey'], testHexPubkey);
    });

    test('Parses /offers/:author/:dTag route', () {
      final route = AppRouter.router.configuration.findMatch(Uri.parse('/offers/$testNpub/cozy-studio'));
      expect(route.matches, isNotEmpty);
      expect(route.pathParameters['author'], testNpub);
      expect(route.pathParameters['dTag'], 'cozy-studio');
    });

    test('Parses /requests/:author/:dTag route', () {
      final route = AppRouter.router.configuration.findMatch(Uri.parse('/requests/$testNpub/japan-trip'));
      expect(route.matches, isNotEmpty);
      expect(route.pathParameters['author'], testNpub);
      expect(route.pathParameters['dTag'], 'japan-trip');
    });

    test('Parses /listings/:author/:dTag route', () {
      final route = AppRouter.router.configuration.findMatch(Uri.parse('/listings/$testNpub/home-base'));
      expect(route.matches, isNotEmpty);
      expect(route.pathParameters['author'], testNpub);
      expect(route.pathParameters['dTag'], 'home-base');
    });

    test('Parses /c/:coordinate addressable coordinate route', () {
      final route = AppRouter.router.configuration.findMatch(Uri.parse('/c/30402:$testHexPubkey:author-home'));
      expect(route.matches, isNotEmpty);
      expect(route.pathParameters['coordinate'], '30402:$testHexPubkey:author-home');
    });

    test('Parses /messages/:pubkey and /chat/:pubkey with query params', () {
      final matchMessages = AppRouter.router.configuration.findMatch(Uri.parse('/messages/$testNpub?name=Alice'));
      expect(matchMessages.matches, isNotEmpty);
      expect(matchMessages.pathParameters['pubkey'], testNpub);
      expect(matchMessages.uri.queryParameters['name'], 'Alice');

      final matchChat = AppRouter.router.configuration.findMatch(Uri.parse('/chat/$testNpub'));
      expect(matchChat.matches, isNotEmpty);
      expect(matchChat.pathParameters['pubkey'], testNpub);
    });

    test('Parses /references/new with subject and name query params', () {
      final match = AppRouter.router.configuration.findMatch(Uri.parse('/references/new?subject=$testNpub&name=Bob'));
      expect(match.matches, isNotEmpty);
      expect(match.uri.queryParameters['subject'], testNpub);
      expect(match.uri.queryParameters['name'], 'Bob');
    });

    test('Parses /offers and /requests filter view routes in Branch 0', () {
      final offersMatch = AppRouter.router.configuration.findMatch(Uri.parse('/offers'));
      expect(offersMatch.matches, isNotEmpty);
      expect(offersMatch.uri.path, '/offers');

      final requestsMatch = AppRouter.router.configuration.findMatch(Uri.parse('/requests'));
      expect(requestsMatch.matches, isNotEmpty);
      expect(requestsMatch.uri.path, '/requests');
    });

    test('Parses static routes: /settings, /about, /login, /onboarding, /offers/new, /requests/new', () {
      final settings = AppRouter.router.configuration.findMatch(Uri.parse('/settings'));
      expect(settings.matches, isNotEmpty);

      final about = AppRouter.router.configuration.findMatch(Uri.parse('/about'));
      expect(about.matches, isNotEmpty);

      final login = AppRouter.router.configuration.findMatch(Uri.parse('/login'));
      expect(login.matches, isNotEmpty);

      final onboarding = AppRouter.router.configuration.findMatch(Uri.parse('/onboarding'));
      expect(onboarding.matches, isNotEmpty);

      final newOffer = AppRouter.router.configuration.findMatch(Uri.parse('/offers/new'));
      expect(newOffer.matches, isNotEmpty);

      final newRequest = AppRouter.router.configuration.findMatch(Uri.parse('/requests/new'));
      expect(newRequest.matches, isNotEmpty);
    });

    test('Parses /profile/travel-edit and /profile/edit without matching dynamic /profile/:pubkey', () {
      final travelEditMatch = AppRouter.router.configuration.findMatch(Uri.parse('/profile/travel-edit'));
      expect(travelEditMatch.matches, isNotEmpty);
      expect(travelEditMatch.pathParameters.containsKey('pubkey'), isFalse);

      final editMatch = AppRouter.router.configuration.findMatch(Uri.parse('/profile/edit'));
      expect(editMatch.matches, isNotEmpty);
      expect(editMatch.pathParameters.containsKey('pubkey'), isFalse);
    });
  });

  group('AppRouter Navigation Helper Tests', () {
    testWidgets('App renders main tabs via routerConfig', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            relayConfigProvider.overrideWithValue(RelayConfig(prefs, initialRelays: [])),
            discoverListingsProvider.overrideWith((ref) => Stream.value([])),
            conversationsProvider.overrideWith((ref) => Future.value([])),
            userProfileProvider.overrideWith((ref, pubkey) => Future.value(null)),
            userTravelProfileProvider.overrideWith((ref, pubkey) => Future.value(null)),
          ],
          child: const HospitalityLibreApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Hospitality Libre'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Navigating to unknown route displays 404 Page Not Found', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            relayConfigProvider.overrideWithValue(RelayConfig(prefs, initialRelays: [])),
            discoverListingsProvider.overrideWith((ref) => Stream.value([])),
            conversationsProvider.overrideWith((ref) => Future.value([])),
            userProfileProvider.overrideWith((ref, pubkey) => Future.value(null)),
            userTravelProfileProvider.overrideWith((ref, pubkey) => Future.value(null)),
          ],
          child: const HospitalityLibreApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Go to an invalid path
      AppRouter.router.go('/some/unknown/path');
      await tester.pumpAndSettle();

      expect(find.text('404 - Page Not Found'), findsOneWidget);
      expect(find.text('Go to Discover'), findsOneWidget);

      // Return to Discover
      await tester.tap(find.text('Go to Discover'));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping Hosts and Travelers filter buttons synchronizes router URL', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            relayConfigProvider.overrideWithValue(RelayConfig(prefs, initialRelays: [])),
            discoverListingsProvider.overrideWith((ref) => Stream.value([])),
            conversationsProvider.overrideWith((ref) => Future.value([])),
            userProfileProvider.overrideWith((ref, pubkey) => Future.value(null)),
            userTravelProfileProvider.overrideWith((ref, pubkey) => Future.value(null)),
          ],
          child: const HospitalityLibreApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/discover');

      // Tap Hosts segment
      await tester.tap(find.text('Hosts'));
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/offers');

      // Tap Travelers segment
      await tester.tap(find.text('Travelers'));
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/requests');

      // Tap All segment
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/discover');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
