import 'package:audioplayers/audioplayers.dart';

/// Tiny sound-effect helper. Fails silently if audio is unavailable.
/// Sounds live in assets/sfx/ (regenerate them with tool/gen_sfx.py).
class Sfx {
  static bool enabled = true;
  static final List<AudioPlayer> _players = [];
  static int _next = 0;

  static void play(String name) {
    if (!enabled) return;
    try {
      if (_players.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _players.add(AudioPlayer());
        }
      }
      final p = _players[_next++ % _players.length];
      p.play(AssetSource('sfx/$name.wav')).catchError((_) {});
    } catch (_) {}
  }
}
