import 'package:cursed_auction_house/main.dart';
import 'package:cursed_auction_house/models.dart';
import 'package:cursed_auction_house/state.dart';
import 'package:cursed_auction_house/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('menu renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Profile.load();
    await tester.pumpWidget(const CursedApp());
    expect(find.textContaining('AUCTION HOUSE'), findsOneWidget);
  });

  test('engine starts a lot with five rivals', () {
    final g = GameState(cfg: diffs[1], roster: [0, 1, 2, 3, 4], charmPool: const [CharmType.seer, CharmType.ward, CharmType.gilded]);
    g.startRound();
    expect(g.lot, isNotNull);
    expect(g.bidders.length, 5);
    expect(g.gold, diffs[1].startGold);
  });
}
