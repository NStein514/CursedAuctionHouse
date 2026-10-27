import 'package:flutter/material.dart';
import 'models.dart';
import 'state.dart';

/// Everything you have learned about each rival. Personas are never shown;
/// tag your best guess. Correct reads pay +100🪙 each at the end of the season.
class DossierScreen extends StatefulWidget {
  final GameState g;
  const DossierScreen({super.key, required this.g});
  @override
  State<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends State<DossierScreen> {
  GameState get g => widget.g;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rival Dossier')),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          Card(
            child: ExpansionTile(
              title: const Text('Field guide: rival types'),
              subtitle: const Text('Tag each rival below. +100🪙 per correct read at season end.'),
              children: [
                for (final p in Persona.values) ListTile(dense: true, title: Text(p.label), subtitle: Text(p.desc)),
              ],
            ),
          ),
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
          Text('"${b.blurb}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white54)),
          Text('Purse: ${b.purse} · Wins: ${b.wins} · Bluffs exposed: ${b.bluffsExposed}', style: const TextStyle(color: Colors.white70)),
          Row(children: [
            const Text('Your read: '),
            DropdownButton<Persona?>(
              value: b.guess,
              hint: const Text('Unknown'),
              items: [
                const DropdownMenuItem<Persona?>(value: null, child: Text('Unknown')),
                for (final p in Persona.values) DropdownMenuItem<Persona?>(value: p, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => b.guess = v),
            ),
          ]),
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
