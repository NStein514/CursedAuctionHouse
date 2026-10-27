import 'package:flutter/material.dart';
import 'hall_screen.dart';
import 'setup_screen.dart';
import 'sfx.dart';
import 'storage.dart';

const gold = Color(0xFFD4AF37);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Profile.load();
  runApp(const CursedApp());
}

class CursedApp extends StatelessWidget {
  const CursedApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Cursed Auction House',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF120B1A),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A), brightness: Brightness.dark, primary: gold),
        ),
        // Keep a phone-like width when running on desktop or web.
        builder: (context, child) => Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: child),
        ),
        home: const MenuScreen(),
      );
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  void _go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w)).then((_) => setState(() {}));

  @override
  Widget build(BuildContext context) {
    final p = Profile.I;
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🕯️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('CURSED\nAUCTION HOUSE', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 3, color: gold)),
                const SizedBox(height: 20),
                const Text(
                  'Every artifact hides a true value, a secret charm, and maybe a curse.\n\n'
                  'Watch their tells. Learn who bluffs. Taunt the proud, drain the rich, and keep your sanity.',
                  textAlign: TextAlign.center, style: TextStyle(height: 1.5, color: Colors.white70)),
                const SizedBox(height: 16),
                Text('Runs ${p.runs} · Wins ${p.wins} · Best endless ${p.bestEndless} lots',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 24),
                FilledButton.icon(icon: const Icon(Icons.gavel), label: const Text('Enter the Auction'), onPressed: () => _go(const SetupScreen())),
                const SizedBox(height: 8),
                OutlinedButton.icon(icon: const Icon(Icons.emoji_events), label: const Text('Hall of Fame & Unlocks'), onPressed: () => _go(const HallScreen())),
              ]),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Sound',
              icon: Icon(p.sound ? Icons.volume_up : Icons.volume_off),
              onPressed: () {
                setState(() {
                  p.sound = !p.sound;
                  Sfx.enabled = p.sound;
                });
                p.save();
              },
            ),
          ),
        ]),
      ),
    );
  }
}
