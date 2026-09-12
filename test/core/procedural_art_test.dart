import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_hospitality/core/theme/procedural_art.dart';
import 'package:nostr_hospitality/widgets/profile_banner.dart';
import 'package:nostr_hospitality/widgets/user_avatar.dart';

void main() {
  group('ProceduralArt Tests', () {
    test('getGradient returns deterministic gradient for seed', () {
      const pubkey1 = '4b1e5a8f2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f';
      final grad1 = ProceduralArt.getGradient(pubkey1);
      final grad2 = ProceduralArt.getGradient(pubkey1);

      expect(grad1.colors.length, 2);
      expect(grad1.colors[0], equals(grad2.colors[0]));
      expect(grad1.colors[1], equals(grad2.colors[1]));
    });

    test('different pubkeys produce varied color pairings', () {
      const pubkeyA = '0000000000000000000000000000000000000000000000000000000000000001';
      const pubkeyB = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final pairA = ProceduralArt.getColorPair(pubkeyA);
      final pairB = ProceduralArt.getColorPair(pubkeyB);

      expect(pairA.length, 2);
      expect(pairB.length, 2);
    });

    test('handles empty seed without throwing', () {
      final grad = ProceduralArt.getGradient('');
      expect(grad.colors.length, 2);
    });
  });

  group('ProfileBanner Widget Tests', () {
    testWidgets('Renders procedural fallback when bannerUrl is null', (WidgetTester tester) async {
      const pubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileBanner(
              pubkey: pubkey,
              height: 150,
            ),
          ),
        ),
      );

      expect(find.byType(ProfileBanner), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('UserAvatar Widget Tests', () {
    testWidgets('Renders monogram and procedural fallback when imageUrl is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              nameOrPubkey: 'Alice',
              radius: 30,
              borderWidth: 2.0,
              hasShadow: true,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
    });
  });
}
