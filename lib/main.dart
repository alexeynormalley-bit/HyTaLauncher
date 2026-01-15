
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hyta_launcher/ui/theme.dart';
import 'package:hyta_launcher/ui/scaffold.dart';
import 'package:hyta_launcher/services/game_launcher.dart';

import 'package:hyta_launcher/services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService().init();
  runApp(const HyTaLauncherApp());
}

class HyTaLauncherApp extends StatelessWidget {
  const HyTaLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameLauncher()),
      ],
      child: AnimatedBuilder(
        animation: LocalizationService(),
        builder: (context, _) {
          return MaterialApp(
            title: 'HyTaLauncher',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.strict,
            home: const MainScaffold(),
          );
        }
      ),
    );
  }
}
