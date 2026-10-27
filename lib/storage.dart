import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'sfx.dart';
import 'state.dart';

class RunRecord {
  final String mode, diff, grade;
  final int score, rounds, gold, date;
  final bool won;
  RunRecord(this.mode, this.diff, this.grade, this.score, this.rounds, this.gold, this.date, this.won);

  Map<String, dynamic> toJson() => {'mode': mode, 'diff': diff, 'grade': grade, 'score': score, 'rounds': rounds, 'gold': gold, 'date': date, 'won': won};
  factory RunRecord.fromJson(Map<String, dynamic> m) => RunRecord(
      (m['mode'] ?? 'Season') as String, (m['diff'] ?? '') as String, (m['grade'] ?? 'F') as String,
      (m['score'] ?? 0) as int, (m['rounds'] ?? 0) as int, (m['gold'] ?? 0) as int, (m['date'] ?? 0) as int, (m['won'] ?? false) as bool);
}

/// Saved progress: lifetime stats, hall of fame, unlocks and settings.
class Profile {
  static final Profile I = Profile._();
  Profile._();

  int runs = 0, wins = 0, lotsWon = 0, cursesTaken = 0, cursesWarded = 0, bestEndless = 0, bestReads = 0, bestGradeRank = 0;
  final Set<String> beaten = {};
  List<RunRecord> hall = [];
  bool sound = true, unlockAll = false;
  SharedPreferences? _prefs;

  static Future<void> load() async {
    try {
      I._prefs = await SharedPreferences.getInstance();
      final raw = I._prefs!.getString('profile');
      if (raw != null) I._read(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
    Sfx.enabled = I.sound;
  }

  void _read(Map<String, dynamic> m) {
    int i(String k) => (m[k] ?? 0) as int;
    runs = i('runs');
    wins = i('wins');
    lotsWon = i('lotsWon');
    cursesTaken = i('cursesTaken');
    cursesWarded = i('cursesWarded');
    bestEndless = i('bestEndless');
    bestReads = i('bestReads');
    bestGradeRank = i('bestGradeRank');
    sound = (m['sound'] ?? true) as bool;
    unlockAll = (m['unlockAll'] ?? false) as bool;
    beaten..clear()..addAll(((m['beaten'] ?? []) as List).cast<String>());
    hall = [for (final h in (m['hall'] ?? []) as List) RunRecord.fromJson(h as Map<String, dynamic>)];
  }

  Future<void> save() async {
    try {
      await _prefs?.setString(
          'profile',
          jsonEncode({
            'runs': runs, 'wins': wins, 'lotsWon': lotsWon, 'cursesTaken': cursesTaken, 'cursesWarded': cursesWarded,
            'bestEndless': bestEndless, 'bestReads': bestReads, 'bestGradeRank': bestGradeRank,
            'sound': sound, 'unlockAll': unlockAll, 'beaten': beaten.toList(), 'hall': [for (final h in hall) h.toJson()],
          }));
    } catch (_) {}
  }

  Future<void> reset() async {
    runs = wins = lotsWon = cursesTaken = cursesWarded = bestEndless = bestReads = bestGradeRank = 0;
    beaten.clear();
    hall = [];
    unlockAll = false;
    await save();
  }

  // ---------- unlock rules ----------
  static const _rivalHints = {
    5: 'Finish any run.',
    6: 'Earn a grade of B or better.',
    7: 'Suffer 3 curses (lifetime).',
    8: 'Get 3+ correct reads in one run.',
    9: 'Win a season on Dealer or higher.',
  };

  bool rivalOpen(int i) {
    if (unlockAll || i < 5) return true;
    switch (i) {
      case 5: return runs >= 1;
      case 6: return bestGradeRank >= 3;
      case 7: return cursesTaken >= 3;
      case 8: return bestReads >= 3;
      default: return beaten.any((d) => d != 'apprentice');
    }
  }

  String? rivalHint(int i) => rivalOpen(i) ? null : _rivalHints[i];

  bool diffOpen(Difficulty d) {
    if (unlockAll) return true;
    switch (d) {
      case Difficulty.apprentice:
      case Difficulty.dealer: return true;
      case Difficulty.master: return beaten.any((x) => x != 'apprentice');
      case Difficulty.nightmare: return beaten.contains('master') || beaten.contains('nightmare');
    }
  }

  String? diffHint(Difficulty d) => diffOpen(d) ? null : (d == Difficulty.master ? 'Win a season on Dealer.' : 'Win a season on Master.');

  bool charmOpen(CharmType t) {
    if (unlockAll) return true;
    switch (t) {
      case CharmType.haggler: return lotsWon >= 10;
      case CharmType.mirror: return cursesTaken >= 5;
      case CharmType.lantern: return runs >= 3;
      case CharmType.smoke: return wins >= 1;
      default: return true;
    }
  }

  String? charmHint(CharmType t) {
    if (charmOpen(t)) return null;
    return switch (t) {
      CharmType.haggler => 'Win 10 lots (lifetime).',
      CharmType.mirror => 'Suffer 5 curses (lifetime).',
      CharmType.lantern => 'Finish 3 runs.',
      _ => 'Win a season.',
    };
  }

  List<CharmType> get charmPool => [for (final t in CharmType.values) if (charmOpen(t)) t];

  Set<String> _unlockedNames() {
    final pool = bidderPool(Random());
    return {
      for (var i = 0; i < pool.length; i++) if (rivalOpen(i)) '${pool[i].avatar} ${pool[i].name}',
      for (final t in CharmType.values) if (charmOpen(t)) '✨ ${Charm(t).name}',
      for (final d in Difficulty.values) if (diffOpen(d)) '${diffs[d.index].emoji} ${diffs[d.index].name} difficulty',
    };
  }

  /// Records a finished run. Returns the names of anything newly unlocked.
  List<String> record(GameState g) {
    final before = _unlockedNames();
    runs++;
    lotsWon += g.lotsWon;
    cursesTaken += g.cursesTaken;
    cursesWarded += g.cursesWarded;
    bestReads = max(bestReads, g.reads);
    bestGradeRank = max(bestGradeRank, g.gradeRank);
    if (g.won) {
      wins++;
      beaten.add(g.cfg.name.toLowerCase());
    }
    if (g.endless) bestEndless = max(bestEndless, g.completed);
    hall.add(RunRecord(g.endless ? 'Endless' : 'Season', g.cfg.name, g.grade, g.score, g.completed, g.gold, DateTime.now().millisecondsSinceEpoch, g.won));
    hall.sort((a, b) => b.score.compareTo(a.score));
    if (hall.length > 10) hall = hall.sublist(0, 10);
    save();
    return [for (final n in _unlockedNames()) if (!before.contains(n)) n];
  }
}
