import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr_hospitality/main.dart';
import 'package:nostr_hospitality/core/nostr/relay_config.dart';
import 'package:nostr_hospitality/core/providers/app_providers.dart';

void main() {
  testWidgets('App renders main navigation without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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

    await tester.pump();
    expect(find.text('Hospitality Libre'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Unmount and flush any pending microtasks
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
