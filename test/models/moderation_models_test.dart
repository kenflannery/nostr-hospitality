import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:nostr_hospitality/core/constants/nostr_constants.dart';
import 'package:nostr_hospitality/models/moderation_models.dart';

void main() {
  group('Moderation Models Tests', () {
    const myPubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    const badPubkey = 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
    const badEventId = 'e0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

    group('Kind 10000 MuteList', () {
      test('Parses MuteList correctly', () {
        final nip01 = Nip01Event(
          pubKey: myPubkey,
          kind: NostrConstants.muteListKind,
          tags: [
            ['p', badPubkey],
            ['p', 'another_pubkey'],
          ],
          content: '',
          createdAt: 1719234800,
        );

        final muteList = MuteList.fromNip01Event(nip01);
        expect(muteList, isNotNull);
        expect(muteList!.mutedPubkeys.length, 2);
        expect(muteList.isMuted(badPubkey), true);
        expect(muteList.isMuted('safe_pubkey'), false);
      });

      test('Converts MuteList to Nip01Event', () {
        final muteList = MuteList(
          mutedPubkeys: {badPubkey},
          createdAt: DateTime.now(),
        );

        final event = muteList.toNip01Event(authorPubkey: myPubkey);
        expect(event.kind, NostrConstants.muteListKind);
        expect(event.tags.length, 1);
        expect(event.tags.first, ['p', badPubkey]);
      });
    });

    group('Kind 1984 ReportEvent', () {
      test('Parses pubkey report correctly', () {
        final nip01 = Nip01Event(
          pubKey: myPubkey,
          kind: NostrConstants.reportKind,
          tags: [
            ['p', badPubkey, NostrConstants.reportSpam],
          ],
          content: 'Bot account spamming commercial links.',
          createdAt: 1719234800,
        );

        final report = ReportEvent.fromNip01Event(nip01);
        expect(report, isNotNull);
        expect(report!.targetPubkey, badPubkey);
        expect(report.reportType, NostrConstants.reportSpam);
        expect(report.content, 'Bot account spamming commercial links.');
      });

      test('Parses event report correctly', () {
        final nip01 = Nip01Event(
          pubKey: myPubkey,
          kind: NostrConstants.reportKind,
          tags: [
            ['e', badEventId, NostrConstants.reportNudity],
            ['p', badPubkey],
          ],
          content: 'Inappropriate listing photo.',
          createdAt: 1719234800,
        );

        final report = ReportEvent.fromNip01Event(nip01);
        expect(report, isNotNull);
        expect(report!.targetEventId, badEventId);
        expect(report.reportType, NostrConstants.reportNudity);
      });
    });

    group('Kind 30015 CautionaryTagSet', () {
      test('Default set flags default caution tags', () {
        final set = CautionaryTagSet.defaultSet();
        expect(set.isCautionary('creepy'), true);
        expect(set.isCautionary('unresponsive'), true);
        expect(set.isCautionary('great_cook'), false);
      });

      test('Parses custom Kind 30015 event and evaluates caution tags', () {
        final nip01 = Nip01Event(
          pubKey: myPubkey,
          kind: NostrConstants.interestSetKind,
          tags: [
            ['d', NostrConstants.cautionaryTagsSetDTag],
            ['t', 'loud_music'],
            ['t', 'creepy'],
          ],
          content: '',
          createdAt: 1719234800,
        );

        final customSet = CautionaryTagSet.fromNip01Event(nip01);
        expect(customSet, isNotNull);
        expect(customSet!.isCautionary('loud_music'), true);
        expect(customSet.isCautionary('creepy'), true);
        expect(customSet.isCautionary('great_cook'), false);
      });
    });
  });
}
