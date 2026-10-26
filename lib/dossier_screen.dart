import 'package:flutter/material.dart';
import 'models.dart';
import 'state.dart';

/// Everything you have learned about each rival. Persona is never shown;
/// you infer it from tells, category interest, wins, and purse.
class DossierScreen extends StatelessWidget {
  final GameState g;
  const DossierScreen({super.key, required this.g});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rival Dossier')),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          for (final b in g.bidders) _card(b),
        ]),
      );

  Widget _card(Bidder b) {
    final totalBids = b.bidsByCat.values.fold(0, (a, c) => a + c);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${b.avatar} ${b.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Purse: ${b.purse} · Wins: ${b.wins} · Bluffs exposed: ${b.bluffsExposed}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          const Text('Interest by category (bids seen)', style: TextStyle(fontWeight: FontWeight.w600)),
          for (final c in Category.values)
            Row(children: [
              SizedBox(width: 80, child: Text('${c.emoji} ${c.label}', style: const TextStyle(fontSize: 12))),
              Expanded(child: LinearProgressIndicator(value: totalBids == 0 ? 0 : (b.bidsByCat[c] ?? 0) / totalBids)),
            ]),
          const SizedBox(height: 8),
          const Text('Tells', style: TextStyle(fontWeight: FontWeight.w600)),
          if (b.tellStats.isEmpty) const Text('No data yet. Watch and wait.', style: TextStyle(color: Colors.white54)),
          for (final e in b.tellStats.entries)
            Text('• ${e.key}: bluff ${e.value[0]}/${e.value[1]} (${(100 * e.value[0] / e.value[1]).round()}%)',
                style: TextStyle(color: e.value[0] / e.value[1] > .5 ? Colors.redAccent : Colors.greenAccent)),
        ]),
      ),
    );
  }
}
