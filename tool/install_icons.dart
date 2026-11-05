import 'dart:convert';
import 'dart:io';

import 'package:flutter_launcher_icons/main.dart' as launcher;

Future<void> main() async {
  bool exists(String platform) => Directory(platform).existsSync();
  final platforms = ['android', 'ios', 'web', 'windows', 'macos'];
  if (!platforms.any(exists)) {
    stdout.writeln(
        'Launcher artwork is ready. Run setup.sh or setup.ps1 to create platform projects and install it.');
    return;
  }
  final config = File('.dart_tool/launcher-icons.json');
  await config.parent.create(recursive: true);
  await config.writeAsString(jsonEncode({
    'flutter_launcher_icons': {
      'image_path': 'assets/art/app-icon-v1.png',
      'android': exists('android'),
      'ios': exists('ios'),
      'remove_alpha_ios': true,
      'web': {
        'generate': exists('web'),
        'background_color': '#171222',
        'theme_color': '#171222',
      },
      'windows': {'generate': exists('windows'), 'icon_size': 256},
      'macos': {'generate': exists('macos')},
    }
  }));
  try {
    await launcher.createIconsFromArguments(['-f', config.path]);
  } finally {
    if (await config.exists()) await config.delete();
  }
}
