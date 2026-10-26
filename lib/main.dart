import 'package:flutter/material.dart';
import 'setup_screen.dart';

void main() => runApp(const CursedApp());

const gold = Color(0xFFD4AF37);

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

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🕯️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text('CURSED\nAUCTION HOUSE', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 3, color: gold)),
              const SizedBox(height: 20),
              const Text(
                'Ten lots. Five rivals of your choosing. Every artifact hides a true value, a secret charm, and maybe a curse.\n\n'
                'Watch their tells. Learn who bluffs. Taunt the proud, drain the rich, and hit your difficulty's target with your sanity intact.',
                textAlign: TextAlign.center, style: TextStyle(height: 1.5, color: Colors.white70)),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.gavel),
                label: const Text('Enter the Auction'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen())),
              ),
            ]),
          ),
        ),
      );
}
