import 'package:cursed_auction_house/auction_screen.dart';
import 'package:cursed_auction_house/models.dart';
import 'package:cursed_auction_house/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one summary and one Black Market per result', (tester) async {
    final g = GameState(
        cfg: diffs[2],
        roster: [0, 1, 2, 3, 4],
        charmPool: CharmType.values.toList());
    await tester.pumpWidget(MaterialApp(home: AuctionScreen(g: g)));
    await tester.pump();

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    void endRound() {
      g.result = AuctionResult(g.lot!, 'Nobody', 0, 0, false, const ['No bids.']);
      g.notifyListeners();
    }

    // Round 3 is a Black Market round.
    g.round = 3;
    endRound();
    await settle();
    expect(find.text('Unsold'), findsOneWidget);

    await tester.tap(find.text('Next lot'));
    await settle();
    expect(find.textContaining('Black Market'), findsOneWidget);

    // Buying notifies listeners while the result is still current; it must not
    // replay the summary or open a second shop.
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)).first);
    await settle();
    expect(find.text('Unsold'), findsNothing);
    expect(find.textContaining('Black Market'), findsOneWidget);

    await tester.tap(find.text('Leave'));
    await settle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(g.round, 4);

    // The following round has no market.
    endRound();
    await settle();
    await tester.tap(find.text('Next lot'));
    await settle();
    expect(find.textContaining('Black Market'), findsNothing);
    expect(g.round, 5);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
