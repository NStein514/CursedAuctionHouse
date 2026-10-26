import 'dart:math';

enum Category { relic, weapon, tome, jewel, idol }

extension CategoryX on Category {
  String get emoji => const ['🏺', '🗡️', '📜', '💎', '🗿'][index];
  String get label => name[0].toUpperCase() + name.substring(1);
}

enum Persona { miser, gambler, collector, bluffer, occultist, sniper, expert, spiteful, speculator, whale }

enum CharmType { seer, ward, gilded }

class Charm {
  final CharmType type;
  const Charm(this.type);
  String get name => switch (type) {
        CharmType.seer => "Seer's Eye",
        CharmType.ward => 'Ward Sigil',
        CharmType.gilded => 'Gilded Touch',
      };
  String get desc => switch (type) {
        CharmType.seer => "Use on a rival: reveals their true limit for this lot.",
        CharmType.ward => 'Automatic: blocks the next curse that would hit you.',
        CharmType.gilded => 'Automatic: +25% on your next resale.',
      };
}

class Curse {
  final String name, desc;
  final int severity; // 1-5
  const Curse(this.name, this.desc, this.severity);
  int get goldLoss => severity * 90;
  int get sanityLoss => severity * 7;
}

class Artifact {
  final String name, aura;
  final Category category;
  final int trueValue, estimate;
  final Curse? curse;
  final Charm? charm;
  final bool masked; // curse hides from appraisal
  const Artifact(this.name, this.category, this.trueValue, this.estimate,
      this.curse, this.charm, this.aura, this.masked);
}

class Bidder {
  final String name, avatar, bluffTell, honestTell, blurb;
  final Persona persona;
  final Category favorite;
  final double aggression, bluffRate, pride;
  int budget;
  bool folded = false, taunted = false;
  int wins = 0, bluffsExposed = 0, waits = 0;
  final Map<String, List<int>> tellStats = {}; // tell -> [bluffs, total]
  final Map<Category, int> bidsByCat = {};

  Bidder({
    required this.name,
    required this.avatar,
    required this.persona,
    required this.favorite,
    required this.budget,
    required this.aggression,
    required this.bluffRate,
    required this.pride,
    required this.bluffTell,
    required this.honestTell,
    required this.blurb,
  });

  String get purse => budget > 1500
      ? 'Flush'
      : budget > 800
          ? 'Comfortable'
          : 'Running low';
}

/// All rivals you can invite. Personas stay hidden; the blurb is only a rumor.
List<Bidder> bidderPool(Random r) {
  Category fav() => Category.values[r.nextInt(5)];
  return [
    Bidder(name: 'Silas Penny', avatar: '🧐', persona: Persona.miser, favorite: fav(), budget: 900,
        aggression: .2, bluffRate: .05, pride: .2, blurb: 'Old money. Hates parting with it.',
        bluffTell: 'polishes his spectacles', honestTell: 'stares unblinking'),
    Bidder(name: 'Duchess Vane', avatar: '👑', persona: Persona.gambler, favorite: fav(), budget: 1800,
        aggression: .8, bluffRate: .2, pride: .8, blurb: 'Lives for the thrill of the chase.',
        bluffTell: 'laughs too loudly', honestTell: 'snaps her fan shut'),
    Bidder(name: 'Orrin Kade', avatar: '🗝️', persona: Persona.collector, favorite: fav(), budget: 1300,
        aggression: .5, bluffRate: .1, pride: .5, blurb: 'Has a very specific taste.',
        bluffTell: 'strokes his beard', honestTell: 'grips his cane'),
    Bidder(name: 'Madame Vex', avatar: '🎭', persona: Persona.bluffer, favorite: fav(), budget: 1400,
        aggression: .5, bluffRate: .55, pride: .6, blurb: 'Never quite says what she means.',
        bluffTell: 'touches her ring', honestTell: 'leans forward'),
    Bidder(name: 'Brother Morrow', avatar: '🕯️', persona: Persona.occultist, favorite: fav(), budget: 1100,
        aggression: .6, bluffRate: .1, pride: .4, blurb: 'Drawn to dark things.',
        bluffTell: 'murmurs a prayer', honestTell: 'inhales deeply'),
    Bidder(name: 'Ravenna Cross', avatar: '🦉', persona: Persona.sniper, favorite: fav(), budget: 1500,
        aggression: .7, bluffRate: .1, pride: .5, blurb: 'Patient. Watches more than she bids.',
        bluffTell: 'checks her pocket watch', honestTell: 'tilts her head'),
    Bidder(name: 'Professor Ash', avatar: '🔬', persona: Persona.expert, favorite: fav(), budget: 1500,
        aggression: .3, bluffRate: .05, pride: .2, blurb: 'Speaks little. Has seen everything.',
        bluffTell: 'clears his throat', honestTell: 'adjusts his loupe'),
    Bidder(name: 'Lord Harrow', avatar: '🦂', persona: Persona.spiteful, favorite: fav(), budget: 1400,
        aggression: .6, bluffRate: .15, pride: .9, blurb: 'Holds grudges.',
        bluffTell: 'cracks his knuckles', honestTell: 'narrows his eyes'),
    Bidder(name: 'Jinx Marlowe', avatar: '🎲', persona: Persona.speculator, favorite: fav(), budget: 1200,
        aggression: .6, bluffRate: .25, pride: .5, blurb: 'Trusts the catalogue.',
        bluffTell: 'flips a coin', honestTell: 'studies the catalogue'),
    Bidder(name: 'Baron Gilt', avatar: '💰', persona: Persona.whale, favorite: fav(), budget: 2600,
        aggression: .7, bluffRate: 0, pride: .9, blurb: 'Money is no object.',
        bluffTell: 'waves a servant over', honestTell: 'sips his wine'),
  ];
}

const _pre = ['Weeping', 'Gilded', 'Hollow', 'Forgotten', 'Obsidian', 'Crimson', 'Whispering', 'Drowned'];
const _nouns = {
  Category.relic: ['Urn', 'Reliquary', 'Mask'],
  Category.weapon: ['Dagger', 'Scythe', 'Blade'],
  Category.tome: ['Grimoire', 'Codex', 'Scroll'],
  Category.jewel: ['Crown', 'Amulet', 'Locket'],
  Category.idol: ['Idol', 'Effigy', 'Totem'],
};
const _curses = [
  ['Withering Touch', 'Your coins turn to dust.'],
  ['Hungry Dark', 'Something follows you home.'],
  ['Mirror Fever', 'You no longer recognize yourself.'],
  ['Debt of Ash', 'An old creditor collects.'],
  ['Silent Choir', 'Voices beg you to bid higher.'],
];
const _cursedAura = ['The air hums with unease.', 'Candles gutter nearby.', 'You taste copper.', 'Whispers behind the glass.'];
const _calmAura = ['It sits quietly under the lamp.', 'A faint scent of lavender.', 'The room feels warm.', 'Nothing stirs.'];

Artifact makeArtifact(Random r, int round, DiffCfg cfg) {
  final cat = Category.values[r.nextInt(5)];
  final name = '${_pre[r.nextInt(_pre.length)]} ${_nouns[cat]![r.nextInt(3)]}';
  var base = 150 + r.nextInt(250) + round * 60;
  Curse? curse;
  if (r.nextDouble() < ((.25 + round * .06) * cfg.curseChance).clamp(0.0, .95)) {
    final sev = (1 + r.nextInt(1 + (round / 3).ceil())).clamp(1, 5);
    final c = _curses[r.nextInt(_curses.length)];
    curse = Curse(c[0], c[1], sev);
    base = (base * (1 + .15 * sev)).round(); // cursed goods tempt
  }
  final charm = r.nextDouble() < .3 ? Charm(CharmType.values[r.nextInt(3)]) : null;
  final est = ((base * (.65 + r.nextDouble() * .7)) / 10).round() * 10;
  var aura = (curse != null ? _cursedAura : _calmAura)[r.nextInt(4)];
  if (r.nextDouble() < cfg.auraNoise) aura = (curse != null ? _calmAura : _cursedAura)[r.nextInt(4)];
  return Artifact(name, cat, base, est, curse, charm, aura, curse != null && r.nextDouble() < cfg.masked);
}

enum Difficulty { apprentice, dealer, master, nightmare }

class DiffCfg {
  final String name, emoji, desc;
  final int startGold, goal, upkeep, sanityDrain, appraiseCost;
  final double curseChance, curseDamage, rivalBudget, rivalIncome, tellBluff, tellFake, masked, auraNoise;
  const DiffCfg({
    required this.name, required this.emoji, required this.desc,
    required this.startGold, required this.goal, required this.upkeep,
    required this.sanityDrain, required this.appraiseCost,
    required this.curseChance, required this.curseDamage,
    required this.rivalBudget, required this.rivalIncome,
    required this.tellBluff, required this.tellFake,
    required this.masked, required this.auraNoise,
  });
}

/// Indexed by Difficulty.index.
const diffs = [
  DiffCfg(name: 'Apprentice', emoji: '🌱', desc: 'Gentle curses, clear tells, modest rivals.',
      startGold: 1200, goal: 2500, upkeep: 0, sanityDrain: 0, appraiseCost: 40,
      curseChance: .8, curseDamage: .6, rivalBudget: .8, rivalIncome: .8,
      tellBluff: .9, tellFake: .05, masked: .05, auraNoise: .15),
  DiffCfg(name: 'Dealer', emoji: '⚖️', desc: 'Fair odds, but the house charges fees every lot.',
      startGold: 1000, goal: 3500, upkeep: 50, sanityDrain: 0, appraiseCost: 60,
      curseChance: 1, curseDamage: 1, rivalBudget: 1, rivalIncome: 1,
      tellBluff: .8, tellFake: .15, masked: .15, auraNoise: .25),
  DiffCfg(name: 'Master', emoji: '🔥', desc: 'Rich rivals, shaky tells, vicious curses.',
      startGold: 900, goal: 4000, upkeep: 90, sanityDrain: 1, appraiseCost: 100,
      curseChance: 1.25, curseDamage: 1.5, rivalBudget: 1.25, rivalIncome: 1.2,
      tellBluff: .7, tellFake: .25, masked: .3, auraNoise: .35),
  DiffCfg(name: 'Nightmare', emoji: '💀', desc: 'Ruinous curses. Your sanity bleeds every lot.',
      startGold: 800, goal: 4500, upkeep: 130, sanityDrain: 3, appraiseCost: 150,
      curseChance: 1.5, curseDamage: 2, rivalBudget: 1.5, rivalIncome: 1.4,
      tellBluff: .6, tellFake: .35, masked: .4, auraNoise: .45),
];
