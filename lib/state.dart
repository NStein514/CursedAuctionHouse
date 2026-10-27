import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'sfx.dart';

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

class ShopItem {
  final String name, desc, kind;
  final int price;
  final CharmType? charm;
  const ShopItem(this.name, this.desc, this.kind, this.price, [this.charm]);
}

const shopItems = [
  ShopItem("Seer's Eye", "Read one rival's limit on a lot.", 'charm', 120, CharmType.seer),
  ShopItem('Ward Sigil', 'Blocks the next curse.', 'charm', 150, CharmType.ward),
  ShopItem('Gilded Touch', '+25% on your next resale.', 'charm', 100, CharmType.gilded),
  ShopItem('Smoke Bomb', 'Make one rival flee a lot.', 'charm', 130, CharmType.smoke),
  ShopItem('Lantern of Truth', 'See a lot true value and curse.', 'charm', 110, CharmType.lantern),
  ShopItem("Haggler's Seal", '20% off your next win.', 'charm', 120, CharmType.haggler),
  ShopItem('Mirror Shard', 'Halves the next curse.', 'charm', 140, CharmType.mirror),
  ShopItem('Cleansing Rite', 'Restore 20 sanity.', 'rite', 140),
  ShopItem("Informant's Rumor", "Learn one rival's true nature.", 'rumor', 150),
];

class GameState extends ChangeNotifier {
  static const maxRounds = 10;
  final DiffCfg cfg;
  final bool endless;
  final List<CharmType> charmPool;
  final rng = Random();
  late final List<Bidder> bidders;
  late int gold = cfg.startGold;
  int sanity = 100, round = 0, completed = 0, startBid = 20, currentBid = 20, shownEstimate = 0;
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

  GameState({required this.cfg, required List<int> roster, required this.charmPool, this.endless = false}) {
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

  // ---------- derived state ----------
  int _r10(num v) => (v / 10).round() * 10;
  bool get hasTop => playerTop || topBidder != null;
  String get topName => playerTop ? 'You' : (topBidder?.name ?? 'No one');
  int get minNext => hasTop ? currentBid + max(10, _r10(currentBid * .08)) : startBid;
  int bidAmount(double pct) => max(minNext, hasTop ? _r10(currentBid * (1 + pct)) : startBid);
  bool get canAct => !busy && !playerFolded && !playerTop && result == null;
  bool get canCharm => !busy && !playerFolded && result == null;
  bool get isFinale => endless ? round % 10 == 0 : round == maxRounds;
  bool get shopRound => !ended && (endless ? round % 4 == 0 : (round == 3 || round == 6 || round == 8));
  int get reads => bidders.where((b) => b.guess == b.persona).length;
  List<ShopItem> get shopStock => [for (final i in shopItems) if (i.charm == null || charmPool.contains(i.charm)) i];

  int get gradeRank {
    if (endless) return completed >= 25 ? 5 : completed >= 18 ? 4 : completed >= 12 ? 3 : completed >= 7 ? 2 : 1;
    if (sanity <= 0 || gold < 20) return 0;
    final r = gold / cfg.goal;
    if (r >= 1.3 && sanity >= 50) return 5;
    if (r >= 1) return 4;
    if (r >= .75) return 3;
    if (r >= .5) return 2;
    return 1;
  }

  String get grade => 'FDCBAS'[gradeRank];
  int get score => endless ? completed * 100 + max(0, gold) ~/ 2 + sanity * 3 : max(0, gold) + sanity * 5 + (won ? 1000 : 0);

  // ---------- lot setup ----------
  Artifact _boss() {
    const names = ['Crown of Nine Sorrows', 'Throne of Ash', 'Chalice of Ruin'];
    final v = 2400 + max(0, round - 10) * 120;
    return Artifact(names[((round ~/ 10) - 1).clamp(0, 99) % 3], Category.jewel, v, _r10(v * .8),
        const Curse('Nine Sorrows', 'Every grief it ever caused, at once.', 5), null, 'The air itself screams.', false);
  }

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
    if (endless && round > 1) {
      for (final b in bidders) {
        b.budget += 40 + round * 12;
        if (round % 5 == 0) {
          b.aggression = min(1.0, b.aggression + .05);
          b.bluffRate = min(.8, b.bluffRate + .03);
        }
      }
    }
    final a = lot = isFinale ? _boss() : makeArtifact(rng, round, cfg, charmPool);
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
    if (endless && round > 1 && round % 5 == 0) log.add('Your rivals grow bolder.');
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

  // ---------- player actions ----------
  void appraise() {
    if (appraised || gold < cfg.appraiseCost || result != null) return;
    gold -= cfg.appraiseCost;
    appraised = true;
    final a = lot!;
    final v = (a.trueValue * (.92 + rng.nextDouble() * .16) / 10).round() * 10;
    final c = (a.curse != null && !a.masked) ? 'MALEVOLENT, curse severity ${a.curse!.severity}/5' : 'no curse sensed';
    appraisal = 'Worth about $v🪙; $c.';
    log.add('Appraisal: $appraisal');
    Sfx.play('charm');
    notifyListeners();
  }

  void taunt(Bidder b) {
    if (b.folded || b.taunted || busy || result != null) return;
    b.taunted = true;
    Sfx.play('taunt');
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
    if (!canCharm || !_take(CharmType.seer)) return;
    final c = (_ceil[b]! * (.93 + rng.nextDouble() * .14) / 10).round() * 10;
    log.add("Seer's Eye: ${b.name} will go to about $c🪙 on this lot.");
    Sfx.play('charm');
    notifyListeners();
  }

  void useSmoke(Bidder b) {
    if (!canCharm || b.folded || b == topBidder || !_take(CharmType.smoke)) return;
    b.folded = true;
    log.add('Smoke Bomb! ${b.name} stumbles out coughing.');
    Sfx.play('charm');
    notifyListeners();
  }

  void useLantern() {
    if (!canCharm || !_take(CharmType.lantern)) return;
    final a = lot!;
    appraised = true;
    appraisal = 'LANTERN: worth exactly ${a.trueValue}🪙; ${a.curse != null ? 'CURSED: ${a.curse!.name}, severity ${a.curse!.severity}/5' : 'no curse'}.';
    log.add(appraisal!);
    Sfx.play('charm');
    notifyListeners();
  }

  /// Black Market purchase. Returns a message to show the player.
  String buy(ShopItem it) {
    if (gold < it.price) return 'Not enough gold.';
    String msg;
    if (it.charm != null) {
      final c = Charm(it.charm!);
      charms.add(c);
      msg = '${c.name} acquired.';
    } else if (it.kind == 'rite') {
      sanity = min(100, sanity + 20);
      msg = 'The rite steadies your mind. +20 sanity.';
    } else {
      final c = bidders.where((b) => b.guess != b.persona).toList();
      if (c.isEmpty) return 'You already know them all.';
      final b = c[rng.nextInt(c.length)];
      b.guess = b.persona;
      msg = 'The informant whispers: ${b.name} is a ${b.persona.label}.';
    }
    gold -= it.price;
    Sfx.play('coin');
    notifyListeners();
    return msg;
  }

  void retire() {
    if (busy || result != null || ended) return;
    profilerBonus = reads * 100;
    gold += profilerBonus;
    ended = true;
    endReason = 'You retire with your fortune.${reads > 0 ? ' Your reads earned +$profilerBonus🪙.' : ''}';
    Sfx.play('win');
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
    Sfx.play('bid');
    await _bidderRound();
  }

  Future<void> playerPass() async {
    if (busy || playerFolded || result != null) return;
    playerFolded = true;
    log.add('You step back from the bidding.');
    await _bidderRound();
  }

  // ---------- rival AI ----------
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
      if (!playerFolded) Sfx.play('fold');
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
    log.add('${b.name} bids $next🪙 and $tell.');
    if (!playerFolded) Sfx.play('bid');
  }

  // ---------- resolution ----------
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
    var winner = 'Nobody', net = 0, cursed = false;
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
      if (_take(CharmType.haggler)) {
        final d = (price * .2).round();
        gold += d;
        net += d;
        notes.add("Haggler's Seal: $d🪙 off the price.");
      }
      notes.add('Resold for $sale🪙 (true value ${a.trueValue}🪙).');
      final c = a.curse;
      if (c != null) {
        if (_take(CharmType.ward)) {
          cursesWarded++;
          notes.add('Ward Sigil shatters, blocking ${c.name}.');
        } else {
          var dmg = cfg.curseDamage;
          if (_take(CharmType.mirror)) {
            dmg *= .5;
            notes.add('Mirror Shard cracks, halving the curse.');
          }
          final gl = (c.goldLoss * dmg).round();
          final sl = (c.sanityLoss * dmg).round();
          cursesTaken++;
          cursed = true;
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
    completed++;
    final fee = cfg.upkeep + (endless ? round * 8 : 0);
    if (fee > 0) {
      gold -= fee;
      notes.add('House fees: -$fee🪙.');
    }
    final drain = cfg.sanityDrain + (endless ? round ~/ 6 : 0);
    if (drain > 0) {
      sanity -= drain;
      notes.add('The house whispers. -$drain sanity.');
    }
    sanity = sanity.clamp(0, 100);
    if (gold > peakGold) peakGold = gold;
    if (!endless && round >= maxRounds && sanity > 0) {
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
    } else if (!endless && round >= maxRounds) {
      ended = true;
      won = gold >= cfg.goal;
      endReason = won ? 'Master dealer! Your name is whispered in every cellar.' : 'The season ends. You fell short of ${cfg.goal}🪙.';
    }
    if (ended && !won) {
      Sfx.play('lose');
    } else if (cursed) {
      Sfx.play('curse');
    } else if (winner == 'You') {
      Sfx.play('win');
    } else if (winner == 'Nobody') {
      Sfx.play('fold');
    } else {
      Sfx.play('gavel');
    }
    result = AuctionResult(a, winner, price, net, winner == 'You', notes);
    busy = false;
    notifyListeners();
  }
}
