import 'dart:math';
import 'package:cursed_auction_house/game_art.dart';
import 'package:cursed_auction_house/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hidden properties cannot change artifact artwork', () {
    const calm = Artifact(
        'Weeping Urn', Category.relic, 200, 180, null, null, 'Quiet', false);
    const cursed = Artifact('Weeping Urn', Category.relic, 900, 180,
        Curse('Hidden', 'Secret', 5), null, 'Quiet', true);
    expect(artifactArtIndex(calm), artifactArtIndex(cursed));
  });

  testWidgets('art loads, animates, and stops for reduced motion',
      (tester) async {
    final rival = bidderPool(Random(1)).first;
    Widget scene(bool reduced) => MaterialApp(
            home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
              body: Column(children: [
            RivalPortrait(bidder: rival),
            const ArtifactDisplay(
                artifact: Artifact('Weeping Urn', Category.relic, 200, 180,
                    null, null, 'Quiet', false)),
          ])),
        ));
    await tester.pumpWidget(scene(false));
    await tester.pump(const Duration(milliseconds: 800));
    final transforms = tester.widgetList<Transform>(find.byType(Transform));
    expect(transforms.any((t) => t.transform.storage[13] != 0), isTrue);
    await tester.pumpWidget(scene(true));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<Transform>(find.byType(Transform))
            .every((t) => t.transform.storage[13] == 0),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });
}
