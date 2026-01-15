
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hyta_launcher/ui/theme.dart';
import 'package:hyta_launcher/ui/scaffold.dart';
import 'package:hyta_launcher/services/game_launcher.dart';

void main() {
  runApp(const HyTaLauncherApp());
}

class HyTaLauncherApp extends StatelessWidget {
  const HyTaLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GameLauncher>(create: (_) => GameLauncher()),
      ],
      child: MaterialApp(
        title: 'HyTa Launcher',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.monochrome,
        home: const MainScaffold(),
      ),
    );
  }
}
