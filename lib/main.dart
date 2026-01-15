import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hyta_launcher/ui/scaffold.dart';
import 'package:hyta_launcher/services/game_launcher.dart';
import 'package:hyta_launcher/services/server_manager.dart';
import 'package:hyta_launcher/services/world_manager.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F),
      brightness: Brightness.dark,
    );
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final launcher = GameLauncher();
          launcher.init();
          return launcher;
        }),
        ChangeNotifierProxyProvider<GameLauncher, ServerManager>(
          create: (_) => ServerManager(gameDir: '', javaExe: ''),
          update: (_, gameLauncher, previous) {
            if (previous != null && previous.gameDir == gameLauncher.gameDir) {
              return previous;
            }
            return ServerManager(
              gameDir: gameLauncher.gameDir,
              javaExe: gameLauncher.javaExe,
            );
          },
        ),
        ChangeNotifierProxyProvider<GameLauncher, WorldManager>(
          create: (_) => WorldManager(gameDir: ''),
          update: (_, gameLauncher, previous) {
            if (previous != null && previous.gameDir == gameLauncher.gameDir) {
              return previous;
            }
            return WorldManager(gameDir: gameLauncher.gameDir);
          },
        ),
      ],
      child: AnimatedBuilder(
        animation: LocalizationService(),
        builder: (context, _) {
          return MaterialApp(
            title: 'HyTaLauncher',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: colorScheme,
              scaffoldBackgroundColor: colorScheme.surface,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              navigationRailTheme: NavigationRailThemeData(
                backgroundColor: colorScheme.surfaceContainer,
                selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
                unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
                indicatorColor: colorScheme.primaryContainer,
              ),
            ),
            home: const MainScaffold(),
          );
        }
      ),
    );
  }
}
