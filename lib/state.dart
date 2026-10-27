import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class AuctionResult {
  final Artifact item;
  final String winner;
  final int price, net;
  final bool playerWon;
  final List<String> notes;
  AuctionResult(this.item, this.winner, this.price, this.net, this.playerWon, this.notes);
}

class _Obs {
  final Bidder b;
  final String tell;
  final bool bluff;
  _Obs(this.b, this.tell, this.bluff);
}

class GameState extends ChangeNotifier {
  static const maxRounds = 10;
  final DiffCfg cfg;
  final rng = Random();
  late final List<Bidder> bidders;
  late int gold = cfg.startGold;
  int sanity = 100, round = 0, startBid = 20, currentBid = 20, shownEstimate = 0;
  final charms = <Charm>[];
  int lotsWon = 0, cursesTaken = 0, cursesWarded = 0, peakGold = 0, profit = 0, profilerBonus = 0;
  final log = <String>[];
  final tells = <Bidder, String>{};
  final _ceil = <Bidder, double>{};
  final _obs = <_Obs>[];
  Artifact? lot;
  Bidder? topBidder;
  bool playerTop = false, playerFolded = false, busy = false, appraised = false, ended = false, won = false, _disposed = false;
  String? appraisal, endReason;
  AuctionResult? result;

  GameState({required this.cfg, required List<int> roster}) {
    final pool = bidderPool(rng);
    bidders = [for (final i in roster) pool[i]];
    for (final b in bidders) {
      b.budget = (b.budget * cfg.rivalBudget).round();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  int _r10(num v) => (v / 10).round() * 10;
  bool get isFinale => round == maxRounds;
  bool get shopRound => !ended && (round == 3 || round == 6 || round == 8);

  Artifact _finale() => const Artifact('Crown of Nine Sorrows', Category.jewel, 2400, 1900,
      Curse('Nine Sorrows', 'Every grief it ever caused, at once.', 5), null, 'The air itself screams.', false);

  /// Black Market purchase. Returns a message to show the player.
  String buy(ShopItem it) {
    if (gold < it.price) return 'Not enough gold.';
    String msg;
    switch (it.kind) {
      case 'seer':
        charms.add(const Charm(CharmType.seer));
        msg = "Seer's Eye acquired.";
      case 'ward':
        charms.add(const Charm(CharmType.ward));
        msg = 'Ward Sigil acquired.';
      case 'gilded':
        charms.add(const Charm(CharmType.gilded));
        msg = 'Gilded Touch acquired.';
      case 'rite':
        sanity = min(100, sanity + 20);
        msg = 'The rite steadies your mind. +20 sanity.';
      default: // rumor
        final c = bidders.where((b) => b.guess != b.persona).toList();
        if (c.isEmpty) return 'You already know them all.';
        final b = c[rng.nextInt(c.length)];
        b.guess = b.persona;
        msg = 'The informant whispers: ${b.name} is a ${b.persona.label}.';
    }
    gold -= it.price;
    notifyListeners();
    return msg;
  }

  bool get hasTop => playerTop || topBidder != null;
  String get topName => playerTop ? 'You' : (topBidder?.name ?? 'No one');
  int get minNext => hasTop ? currentBid + max(10, _r10(currentBid * .08)) : startBid;
  int bidAmount(double pct) => max(minNext, hasTop ? _r10(currentBid * (1 + pct)) : startBid);
  bool get canAct => !busy && !playerFolded && !playerTop && result == null;

  void startRound() {
    round++;
    result = null;
    log.clear();
    tells.clear();
    _obs.clear();
    appraised = false;
    appraisal = null;
    playerFolded = playerTop = busy = false;
    topBidder = null;
    final a = lot = isFinale ? _finale() : makeArtifact(rng, round, cfg);
    if (isFinale) {
      for (final b in bidders) {
        b.budget += 600; // they saved up
      }
    }
    shownEstimate = sanity < 40 ? (a.estimate * (.6 + rng.nextDouble() * .8)).round() : a.estimate;
    startBid = max(20, _r10(a.estimate * .25));
    currentBid = startBid;
    for (final b in bidders) {
      b.folded = b.taunted = false;
      b.waits = 0;
      _ceil[b] = min(b.budget.toDouble(), _valuation(b, a) * (1 + b.aggression * .25));
    }
    log.add(isFinale ? 'FINALE: the ${a.name}. Every rival has saved for this. Opening at $startBid🪙.' : 'Lot $round: ${a.name}. Opening at $startBid🪙.');
    notifyListeners();
  }

  double _valuation(Bidder b, Artifact a) {
    var v = a.trueValue * (.85 + rng.nextDouble() * .3);
    switch (b.persona) {
      case Persona.miser: v *= .8;
      case Persona.gambler: v *= 1.15;
      case Persona.collector: v *= a.category == b.favorite ? 1.6 : .65;
      case Persona.bluffer: break;
      case Persona.occultist: v *= a.curse != null ? 1 + .2 * a.curse!.severity : .7;
      case Persona.sniper: v *= 1.05;
      case Persona.expert: v = a.trueValue * (.98 + rng.nextDouble() * .04);
      case Persona.spiteful: v *= .95;
      case Persona.speculator: v = a.estimate * (.9 + rng.nextDouble() * .2) * 1.05;
      case Persona.whale: v = a.trueValue * (.7 + rng.nextDouble() * .8);
    }
    return v;
  }

  void appraise() {
    if (appraised || gold < cfg.appraiseCost || result != null) return;
    gold -= cfg.appraiseCost;
    appraised = true;
    final a = lot!;
    final v = (a.trueValue * (.92 + rng.nextDouble() * .16) / 10).round() * 10;
    final c = (a.curse != null && !a.masked) ? 'MALEVOLENT, curse severity ${a.curse!.severity}/5' : 'no curse sensed';
    appraisal = 'Worth about $v🪙; $c.';
    log.add('Appraisal: $appraisal');
    notifyListeners();
  }

  void taunt(Bidder b) {
    if (b.folded || b.taunted || busy || result != null) return;
    b.taunted = true;
    log.add('You sneer at ${b.name}. Their pride is wounded.');
    if (rng.nextDouble() < .2) {
      sanity -= 4;
      log.add('The room turns cold. ${b.name} mutters a hex. (-4 sanity)');
    }
    notifyListeners();
  }

  bool _take(CharmType t) {
    final i = charms.indexWhere((c) => c.type == t);
    if (i < 0) return false;
    charms.removeAt(i);
    return true;
  }

  void useSeer(Bidder b) {
    if (!_take(CharmType.seer)) return;
    final c = (_ceil[b]! * (.93 + rng.nextDouble() * .14) / 10).round() * 10;
    log.add("Seer's Eye: ${b.name} will go to about $c🪙 on this lot.");
    notifyListeners();
  }

  Future<void> playerBid(double pct) async {
    if (!canAct) return;
    final amt = bidAmount(pct);
    if (amt > gold) {
      log.add('You cannot afford that.');
      notifyListeners();
      return;
    }
    currentBid = amt;
    playerTop = true;
    topBidder = null;
    log.add('You bid $amt🪙.');
    await _bidderRound();
  }

  Future<void> playerPass() async {
    if (busy || playerFolded || result != null) return;
    playerFolded = true;
    log.add('You step back from the bidding.');
    await _bidderRound();
  }

  Future<void> _bidderRound() async {
    busy = true;
    notifyListeners();
    for (var g = 0; g < 60; g++) {
      final active = bidders.where((b) => !b.folded && b != topBidder).toList()..shuffle(rng);
      if (active.isEmpty) break;
      for (final b in active) {
        if (b.folded) continue;
        await Future.delayed(Duration(milliseconds: playerFolded ? 100 : 750));
        if (_disposed) return;
        _bidderTurn(b);
        notifyListeners();
      }
      if (!playerFolded) break;
    }
    final noRivals = bidders.where((b) => !b.folded && b != topBidder).isEmpty;
    if (playerFolded || (noRivals && playerTop)) {
      _finish();
    } else {
      busy = false;
      notifyListeners();
    }
  }

  void _bidderTurn(Bidder b) {
    final next = minNext;
    var ceil = _ceil[b]!;
    if (b.taunted) ceil = min(ceil * (1 + b.pride * .6), b.budget.toDouble());
    if (b.persona == Persona.spiteful && playerTop) ceil = min(ceil * 1.4, b.budget.toDouble());
    if (b.persona == Persona.sniper && b.waits < 2 && next < ceil * .6) {
      b.waits++;
      log.add('${b.name} bides her time.');
      return;
    }
    final afford = next <= b.budget;
    var bluff = false;
    if (afford && next <= ceil) {
      // genuine interest
    } else if (afford && next <= b.budget * .6 && rng.nextDouble() < b.bluffRate) {
      bluff = true;
    } else {
      b.folded = true;
      log.add('${b.name} folds.');
      return;
    }
    currentBid = next;
    topBidder = b;
    playerTop = false;
    final cat = lot!.category;
    b.bidsByCat[cat] = (b.bidsByCat[cat] ?? 0) + 1;
    var showBluff = bluff ? rng.nextDouble() < cfg.tellBluff : rng.nextDouble() < cfg.tellFake;
    if (rng.nextDouble() < (100 - sanity) / 100 * .25) showBluff = !showBluff; // madness
    final tell = showBluff ? b.bluffTell : b.honestTell;
    tells[b] = tell;
    _obs.add(_Obs(b, tell, bluff));
    log.add('${b.name} bids $next🪙 and ${tell}.');
  }

  void _finish() {
    final a = lot!;
    final notes = <String>[];
    final bluffers = <String>{};
    for (final o in _obs) {
      final s = o.b.tellStats.putIfAbsent(o.tell, () => [0, 0]);
      if (o.bluff) {
        s[0]++;
        o.b.bluffsExposed++;
        bluffers.add(o.b.name);
      }
      s[1]++;
    }
    for (final n in bluffers) {
      notes.add('🎭 $n was bluffing at times. Check your dossier.');
    }
    var winner = 'Nobody', net = 0;
    final price = currentBid;
    if (!hasTop) {
      notes.add('No bids. The lot is withdrawn.');
    } else if (playerTop) {
      winner = 'You';
      gold -= price;
      var sale = a.trueValue;
      if (_take(CharmType.gilded)) {
        sale = (sale * 1.25).round();
        notes.add('Gilded Touch boosts the resale.');
      }
      gold += sale;
      net = sale - price;
      notes.add('Resold for $sale🪙 (true value ${a.trueValue}🪙).');
      final c = a.curse;
      if (c != null) {
        if (_take(CharmType.ward)) {
          cursesWarded++;
          notes.add('Ward Sigil shatters, blocking ${c.name}.');
        } else {
          final gl = (c.goldLoss * cfg.curseDamage).round();
          final sl = (c.sanityLoss * cfg.curseDamage).round();
          cursesTaken++;
          gold -= gl;
          sanity -= sl;
          net -= gl;
          notes.add('☠️ CURSE: ${c.name} (sev ${c.severity}). ${c.desc} -$gl🪙, -$sl sanity.');
        }
      }
      if (a.charm != null) {
        charms.add(a.charm!);
        notes.add('You keep a ${a.charm!.name}.');
      }
    } else {
      final w = topBidder!;
      winner = w.name;
      w.budget -= price;
      w.wins++;
      notes.add('It was worth ${a.trueValue}🪙${a.curse != null ? ' and cursed with ${a.curse!.name}' : ', with no curse'}.');
    }
    if (winner == 'You') {
      lotsWon++;
      profit += net;
    }
    for (final b in bidders) {
      b.budget += ((120 + rng.nextInt(120)) * cfg.rivalIncome).round();
    }
    if (cfg.upkeep > 0) {
      gold -= cfg.upkeep;
      notes.add('House fees: -${cfg.upkeep}🪙.');
    }
    if (cfg.sanityDrain > 0) {
      sanity -= cfg.sanityDrain;
      notes.add('The house whispers. -${cfg.sanityDrain} sanity.');
    }
    sanity = sanity.clamp(0, 100);
    if (gold > peakGold) peakGold = gold;
    if (round >= maxRounds && sanity > 0) {
      final reads = bidders.where((b) => b.guess == b.persona).length;
      profilerBonus = reads * 100;
      if (reads > 0) {
        gold += profilerBonus;
        notes.add('🔎 Profiler bonus: +$profilerBonus🪙 for $reads correct reads.');
      }
    }
    if (sanity <= 0) {
      ended = true;
      endReason = 'Your mind shatters among the whispers.';
    } else if (gold < 20) {
      ended = true;
      endReason = 'Bankrupt. The house seizes your ledger.';
    } else if (round >= maxRounds) {
      ended = true;
      won = gold >= cfg.goal;
      endReason = won ? 'Master dealer! Your name is whispered in every cellar.' : 'The season ends. You fell short of ${cfg.goal}🪙.';
    }
    result = AuctionResult(a, winner, price, net, winner == 'You', notes);
    busy = false;
    notifyListeners();
  }
}

class ShopItem {
  final String name, desc, kind;
  final int price;
  const ShopItem(this.name, this.desc, this.kind, this.price);
}

const shopItems = [
  ShopItem("Seer's Eye", "Read one rival's limit on a lot.", 'seer', 120),
  ShopItem('Ward Sigil', 'Blocks the next curse. Save it for the finale.', 'ward', 150),
  ShopItem('Gilded Touch', '+25% on your next resale.', 'gilded', 100),
  ShopItem('Cleansing Rite', 'Restore 20 sanity.', 'rite', 140),
  ShopItem("Informant's Rumor", "Learn one rival's true nature.", 'rumor', 150),
];
