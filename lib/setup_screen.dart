import 'dart:math';
import 'package:flutter/material.dart';
import 'auction_screen.dart';
import 'main.dart' show gold;
import 'models.dart';
import 'state.dart';

/// Pick a difficulty and exactly five rivals before entering the auction house.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const need = 5;
  final pool = bidderPool(Random());
  int diff = Difficulty.dealer.index;
  final picked = <int>{0, 1, 2, 3, 4};

  void _randomize() {
    final ids = List.generate(pool.length, (i) => i)..shuffle();
    setState(() => picked..clear()..addAll(ids.take(need)));
  }

  void _start() {
    final roster = picked.toList()..sort();
    Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionScreen(g: GameState(cfg: diffs[diff], roster: roster))));
  }

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: gold);
    return Scaffold(
      appBar: AppBar(title: const Text('Prepare the Auction')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Difficulty', style: head),
        for (var i = 0; i < diffs.length; i++) _diffTile(i),
        const SizedBox(height: 16),
        Row(children: [
          Text('Rivals (${picked.length}/$need)', style: head),
          const Spacer(),
          TextButton.icon(onPressed: _randomize, icon: const Icon(Icons.shuffle), label: const Text('Random')),
        ]),
        const Text('Their personalities are secret. Rumors only.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        for (var i = 0; i < pool.length; i++)
          CheckboxListTile(
            dense: true,
            value: picked.contains(i),
            onChanged: (!picked.contains(i) && picked.length >= need)
                ? null
                : (v) => setState(() => v == true ? picked.add(i) : picked.remove(i)),
            title: Text('${pool[i].avatar} ${pool[i].name}'),
            subtitle: Text(pool[i].blurb),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: picked.length == need ? _start : null,
          icon: const Icon(Icons.gavel),
          label: Text(picked.length == need ? 'Begin the Auction' : 'Pick $need rivals'),
        ),
      ]),
    );
  }

  Widget _diffTile(int i) {
    final c = diffs[i];
    final sel = diff == i;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: sel ? gold : Colors.transparent, width: 2)),
      child: ListTile(
        onTap: () => setState(() => diff = i),
        leading: Text(c.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(c.name),
        subtitle: Text('${c.desc}\nStart ${c.startGold}🪙 · Goal ${c.goal}🪙 · Fees ${c.upkeep}🪙/lot'),
        isThreeLine: true,
        trailing: sel ? const Icon(Icons.check_circle, color: gold) : null,
      ),
    );
  }
}
