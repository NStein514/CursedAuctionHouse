import 'dart:math';
import 'package:flutter/material.dart';
import 'auction_screen.dart';
import 'main.dart' show gold;
import 'models.dart';
import 'state.dart';
import 'storage.dart';

/// Choose mode, difficulty and exactly five rivals before entering the auction house.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const need = 5;
  final pool = bidderPool(Random());
  bool endless = false;
  int diff = Difficulty.dealer.index;
  final picked = <int>{0, 1, 2, 3, 4};
  Profile get pf => Profile.I;

  void _randomize() {
    final ids = [for (var i = 0; i < pool.length; i++) if (pf.rivalOpen(i)) i]..shuffle();
    setState(() => picked..clear()..addAll(ids.take(need)));
  }

  void _start() {
    final roster = picked.toList()..sort();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuctionScreen(g: GameState(cfg: diffs[diff], roster: roster, charmPool: pf.charmPool, endless: endless))),
    );
  }

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: gold);
    return Scaffold(
      appBar: AppBar(title: const Text('Prepare the Auction')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Mode', style: head),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Season'), icon: Icon(Icons.flag)),
            ButtonSegment(value: true, label: Text('Endless'), icon: Icon(Icons.all_inclusive)),
          ],
          selected: {endless},
          onSelectionChanged: (s) => setState(() => endless = s.first),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            endless
                ? 'No end, no goal. Rivals grow richer and bolder, fees climb, and a boss lot arrives every 10 lots. Survive as long as you can, or retire to bank your reads.'
                : 'Ten lots. Hit your difficulty goal before the finale ends.',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        const Text('Difficulty', style: head),
        for (var i = 0; i < diffs.length; i++) _diffTile(i),
        const SizedBox(height: 16),
        Row(children: [
          Text('Rivals (${picked.length}/$need)', style: head),
          const Spacer(),
          TextButton.icon(onPressed: _randomize, icon: const Icon(Icons.shuffle), label: const Text('Random')),
        ]),
        const Text('Personalities are secret. Rumors only. Locked rivals unlock as you play.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        for (var i = 0; i < pool.length; i++) _rivalTile(i),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: picked.length == need ? _start : null,
          icon: const Icon(Icons.gavel),
          label: Text(picked.length == need ? 'Begin the Auction' : 'Pick $need rivals'),
        ),
      ]),
    );
  }

  Widget _rivalTile(int i) {
    final hint = pf.rivalHint(i);
    if (hint != null) {
      return ListTile(dense: true, enabled: false, leading: const Text('🔒', style: TextStyle(fontSize: 22)), title: const Text('Locked rival'), subtitle: Text(hint));
    }
    return CheckboxListTile(
      dense: true,
      value: picked.contains(i),
      onChanged: (!picked.contains(i) && picked.length >= need) ? null : (v) => setState(() => v == true ? picked.add(i) : picked.remove(i)),
      title: Text('${pool[i].avatar} ${pool[i].name}'),
      subtitle: Text(pool[i].blurb),
    );
  }

  Widget _diffTile(int i) {
    final c = diffs[i];
    final hint = pf.diffHint(Difficulty.values[i]);
    final sel = diff == i;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: sel ? gold : Colors.transparent, width: 2)),
      child: ListTile(
        enabled: hint == null,
        onTap: hint == null ? () => setState(() => diff = i) : null,
        leading: Text(hint == null ? c.emoji : '🔒', style: const TextStyle(fontSize: 28)),
        title: Text(c.name),
        subtitle: Text(hint ?? '${c.desc}\nStart ${c.startGold}🪙 · ${endless ? 'No goal' : 'Goal ${c.goal}🪙'} · Fees ${c.upkeep}🪙/lot'),
        isThreeLine: hint == null,
        trailing: sel ? const Icon(Icons.check_circle, color: gold) : null,
      ),
    );
  }
}
