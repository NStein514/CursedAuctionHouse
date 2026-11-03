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

  testWidgets('rival idles pause offstage, resume, and stop when folded',
      (tester) async {
    final rival = bidderPool(Random(1))[2];
    Widget scene(bool enabled) => MaterialApp(
            home: Scaffold(
          body:
              TickerMode(enabled: enabled, child: RivalPortrait(bidder: rival)),
        ));
    await tester.pumpWidget(scene(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(scene(false));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(scene(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    rival.folded = true;
    await tester.pumpWidget(scene(true));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rival art keeps its cell aspect when a tile box is shorter',
      (tester) async {
    // Compact density shrinks ListTile's icon slot below the portrait size.
    final rival = bidderPool(Random(1)).first;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
      body: ListTile(
        dense: true,
        leading: RivalPortrait(bidder: rival, animate: false),
        title: const Text('Silas'),
        subtitle: const Text('Purse: Comfortable'),
      ),
    )));
    await tester.pump();
    final portrait = tester.renderObject<RenderBox>(find.byType(RivalPortrait));
    expect(portrait.size.height, lessThan(portrait.size.width));
    final atlas = tester.renderObject<RenderBox>(find.descendant(
        of: find.byType(RivalPortrait), matching: find.byType(Image)));
    // Five columns by six square rows: a squashed cell changes this ratio.
    expect(atlas.size.width / atlas.size.height, closeTo(5 / 6, .001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rival cycle briefly blinks, glances, and returns to neutral',
      (tester) async {
    final rival = bidderPool(Random(1)).first;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: RivalPortrait(bidder: rival),
    )));
    double atlasTop() => tester
        .widget<Positioned>(find.descendant(
          of: find.byType(RivalPortrait),
          matching: find.byType(Positioned),
        ))
        .top!;
    expect(atlasTop(), 0);
    await tester.pump(const Duration(milliseconds: 2750));
    final blinkTop = atlasTop();
    expect(blinkTop, lessThan(0));
    await tester.pump(const Duration(milliseconds: 2050));
    expect(atlasTop(), lessThan(blinkTop));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(atlasTop(), 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
