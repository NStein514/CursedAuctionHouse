import 'package:flutter/material.dart';
import 'main.dart' show gold;
import 'models.dart';
import 'state.dart';
import 'dossier_screen.dart';

class AuctionScreen extends StatefulWidget {
  final GameState g;
  const AuctionScreen({super.key, required this.g});
  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  GameState get g => widget.g;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    g.addListener(_onChange);
    g.startRound();
  }

  @override
  void dispose() {
    g.removeListener(_onChange);
    g.dispose();
    super.dispose();
  }

  void _onChange() {
    if (g.result != null && !_dialogOpen) {
      _dialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult());
    }
  }

  Future<void> _showResult() async {
    if (!mounted) return;
    final r = g.result!;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(r.winner == 'Nobody' ? 'Unsold' : r.playerWon ? 'Sold to you!' : 'Sold to ${r.winner}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.item.category.emoji} ${r.item.name} · ${r.price}🪙', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final n in r.notes) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(n)),
            if (r.playerWon) Text('Net: ${r.net >= 0 ? '+' : ''}${r.net}🪙', style: TextStyle(color: r.net >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(g.ended ? 'Finish' : 'Next lot'))],
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;
    if (g.ended) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EndScreen(g: g)));
    } else {
      g.startRound();
    }
  }

  void _charms() {
    showModalBottomSheet(
      context: context,
      builder: (c) => ListView(padding: const EdgeInsets.all(16), shrinkWrap: true, children: [
        const Text('Charms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (g.charms.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('None yet. Win lots that hide charms.')),
        for (final ch in g.charms)
          ListTile(
            title: Text(ch.name),
            subtitle: Text(ch.desc),
            trailing: ch.type == CharmType.seer && g.result == null
                ? FilledButton(onPressed: () { Navigator.pop(c); _pickSeer(); }, child: const Text('Use'))
                : null,
          ),
      ]),
    );
  }

  void _pickSeer() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(title: const Text('Read whom?'), children: [
        for (final b in g.bidders.where((b) => !b.folded))
          SimpleDialogOption(onPressed: () { Navigator.pop(c); g.useSeer(b); }, child: Text('${b.avatar} ${b.name}')),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: g,
        builder: (context, _) {
          final a = g.lot;
          if (a == null) return const Scaffold();
          return Scaffold(
            appBar: AppBar(
              title: Text('Lot ${g.round}/${GameState.maxRounds}'),
              actions: [IconButton(icon: const Icon(Icons.menu_book), tooltip: 'Dossier', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DossierScreen(g: g))))],
            ),
            body: ListView(padding: const EdgeInsets.all(12), children: [
              _stats(),
              const SizedBox(height: 8),
              _lotCard(a),
              const SizedBox(height: 8),
              ...g.bidders.map(_bidderTile),
              const SizedBox(height: 8),
              _actions(),
              const SizedBox(height: 8),
              for (final l in g.log.reversed.take(6)) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $l', style: const TextStyle(fontSize: 12, color: Colors.white60))),
            ]),
          );
        },
      );

  Widget _stats() => Row(children: [
        Text('🪙 ${g.gold}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
        Text(' / ${g.cfg.goal}', style: const TextStyle(color: Colors.white54)),
        const Spacer(),
        const Text('🧠 '),
        SizedBox(width: 90, child: LinearProgressIndicator(value: g.sanity / 100, color: g.sanity < 40 ? Colors.redAccent : Colors.tealAccent)),
        Text(' ${g.sanity}'),
      ]);

  Widget _lotCard(Artifact a) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(a.category.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${a.category.label} · est. ${g.shownEstimate}🪙', style: const TextStyle(color: Colors.white70)),
                Text(a.aura, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.purpleAccent)),
                if (g.appraisal != null) Text(g.appraisal!, style: const TextStyle(color: Colors.amberAccent)),
                const SizedBox(height: 6),
                Text('Bid: ${g.hasTop ? g.currentBid : g.startBid}🪙  (${g.topName})', style: const TextStyle(fontSize: 16, color: gold, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),
      );

  Widget _bidderTile(Bidder b) {
    final top = g.topBidder == b;
    final tell = g.tells[b];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: top ? gold : Colors.transparent, width: 2)),
      color: b.folded ? Colors.black26 : null,
      child: ListTile(
        dense: true,
        leading: Text(b.avatar, style: TextStyle(fontSize: 28, color: b.folded ? Colors.white24 : null)),
        title: Text('${b.name}${b.folded ? ' (out)' : ''}${b.taunted ? ' 😡' : ''}'),
        subtitle: Text(tell == null ? 'Purse: ${b.purse}' : 'Purse: ${b.purse} · $tell'),
        trailing: (!b.folded && !b.taunted && !g.busy && g.result == null)
            ? TextButton(onPressed: () => g.taunt(b), child: const Text('Taunt'))
            : null,
      ),
    );
  }

  Widget _actions() {
    final can = g.canAct;
    Widget bid(String t, double p) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: FilledButton(onPressed: can && g.bidAmount(p) <= g.gold ? () => g.playerBid(p) : null, child: Text('$t\n${g.bidAmount(p)}🪙', textAlign: TextAlign.center)),
          ),
        );
    return Column(children: [
      Row(children: [bid(g.hasTop ? 'Raise' : 'Open', 0), bid('+25%', .25), bid('+50%', .5)]),
      Row(children: [
        Expanded(child: Padding(padding: const EdgeInsets.all(2), child: OutlinedButton(onPressed: g.busy || g.playerFolded || g.result != null ? null : g.playerPass, child: const Text('Pass')))),
        Expanded(child: Padding(padding: const EdgeInsets.all(2), child: OutlinedButton(onPressed: g.appraised || g.gold < g.cfg.appraiseCost || g.busy || g.result != null ? null : g.appraise, child: Text('Appraise ${g.cfg.appraiseCost}🪙')))),
        Expanded(child: Padding(padding: const EdgeInsets.all(2), child: OutlinedButton(onPressed: _charms, child: Text('Charms (${g.charms.length})')))),
      ]),
      if (g.busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
    ]);
  }
}

class EndScreen extends StatelessWidget {
  final GameState g;
  const EndScreen({super.key, required this.g});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(g.won ? '🏆' : '💀', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text(g.endReason ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              Text('${g.cfg.name} · Final: ${g.gold}🪙 / ${g.cfg.goal}🪙 · Sanity ${g.sanity}', style: const TextStyle(color: gold, fontSize: 16)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Back to menu')),
            ]),
          ),
        ),
      );
}
