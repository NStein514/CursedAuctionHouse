import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart' show gold;
import 'models.dart';
import 'sfx.dart';
import 'storage.dart';

/// Lifetime stats, unlock progress, top runs and settings.
class HallScreen extends StatefulWidget {
  const HallScreen({super.key});
  @override
  State<HallScreen> createState() => _HallScreenState();
}

class _HallScreenState extends State<HallScreen> {
  Profile get p => Profile.I;

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text('This erases stats, the Hall of Fame and unlocks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await p.reset();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: gold);
    final pool = bidderPool(Random());
    return Scaffold(
      appBar: AppBar(title: const Text('Hall of Fame')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Lifetime', style: head),
        Text('Runs ${p.runs} · Season wins ${p.wins} · Lots won ${p.lotsWon}\n'
            'Curses suffered ${p.cursesTaken} · Warded ${p.cursesWarded}\n'
            'Best endless run ${p.bestEndless} lots · Best reads in a run ${p.bestReads}/5',
            style: const TextStyle(color: Colors.white70, height: 1.5)),
        const SizedBox(height: 16),
        const Text('Top runs', style: head),
        if (p.hall.isEmpty) const Text('No runs yet. Go make some enemies.', style: TextStyle(color: Colors.white54)),
        for (var i = 0; i < p.hall.length; i++) _run(i, p.hall[i]),
        const SizedBox(height: 16),
        const Text('Unlocks', style: head),
        for (var i = 5; i < pool.length; i++)
          ListTile(
            dense: true,
            leading: Text(p.rivalOpen(i) ? pool[i].avatar : '🔒', style: const TextStyle(fontSize: 22)),
            title: Text(p.rivalOpen(i) ? pool[i].name : 'Locked rival'),
            subtitle: Text(p.rivalHint(i) ?? 'Unlocked'),
          ),
        for (final t in const [CharmType.smoke, CharmType.lantern, CharmType.haggler, CharmType.mirror])
          ListTile(
            dense: true,
            leading: Text(p.charmOpen(t) ? '✨' : '🔒', style: const TextStyle(fontSize: 22)),
            title: Text(Charm(t).name),
            subtitle: Text(p.charmHint(t) ?? Charm(t).desc),
          ),
        for (final d in const [Difficulty.master, Difficulty.nightmare])
          ListTile(
            dense: true,
            leading: Text(p.diffOpen(d) ? diffs[d.index].emoji : '🔒', style: const TextStyle(fontSize: 22)),
            title: Text('${diffs[d.index].name} difficulty'),
            subtitle: Text(p.diffHint(d) ?? 'Unlocked'),
          ),
        const SizedBox(height: 16),
        const Text('Settings', style: head),
        SwitchListTile(
          title: const Text('Sound effects'),
          value: p.sound,
          onChanged: (v) {
            setState(() => p.sound = v);
            Sfx.enabled = v;
            p.save();
          },
        ),
        SwitchListTile(
          title: const Text('Unlock everything (for testing)'),
          value: p.unlockAll,
          onChanged: (v) {
            setState(() => p.unlockAll = v);
            p.save();
          },
        ),
        TextButton(onPressed: _reset, child: const Text('Reset all progress', style: TextStyle(color: Colors.redAccent))),
      ]),
    );
  }

  Widget _run(int i, RunRecord r) {
    final d = DateTime.fromMillisecondsSinceEpoch(r.date);
    return ListTile(
      dense: true,
      leading: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
      title: Text('${r.mode} · ${r.diff} · Grade ${r.grade}${r.won ? ' 🏆' : ''}'),
      subtitle: Text('${r.rounds} lots · ${r.gold}🪙 · ${d.month}/${d.day}/${d.year}'),
      trailing: Text('${r.score}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
    );
  }
}
