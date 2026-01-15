import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hyta_launcher/ui/home_page.dart';
import 'package:hyta_launcher/ui/mods_page.dart';
import 'package:hyta_launcher/ui/import_page.dart';
import 'package:hyta_launcher/ui/settings_page.dart';
import 'package:hyta_launcher/ui/logs_page.dart';
import 'package:hyta_launcher/ui/ai_page.dart';
import 'package:hyta_launcher/ui/worlds_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  
  final List<NavigationRailDestination> _destinations = [
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.gameController()),
      selectedIcon: Icon(PhosphorIcons.gameController(PhosphorIconsStyle.fill)),
      label: const Text('Play'),
    ),
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.globe()),
      selectedIcon: Icon(PhosphorIcons.globe(PhosphorIconsStyle.fill)),
      label: const Text('Worlds'),
    ),
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.package()),
      selectedIcon: Icon(PhosphorIcons.package(PhosphorIconsStyle.fill)),
      label: const Text('Mods'),
    ),
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.downloadSimple()),
      selectedIcon: Icon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill)),
      label: const Text('Import'),
    ),
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.robot()),
      selectedIcon: Icon(PhosphorIcons.robot(PhosphorIconsStyle.fill)),
      label: const Text('AI'),
    ),
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.fileText()),
      selectedIcon: Icon(PhosphorIcons.fileText(PhosphorIconsStyle.fill)),
      label: const Text('Logs'),
    ),
    NavigationRailDestination(
      icon: Icon(PhosphorIcons.gear()),
      selectedIcon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill)),
      label: const Text('Settings'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            labelType: NavigationRailLabelType.all,
            extended: false,
            minWidth: 80,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'H',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton.filledTonal(
                    onPressed: () => exit(0),
                    icon: Icon(PhosphorIcons.x()),
                    tooltip: 'Close',
                  ),
                ),
              ),
            ),
            destinations: _destinations,
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _getPage(_currentIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getPage(int index) {
    switch (index) {
      case 0: return const HomePage();
      case 1: return const WorldsPage();
      case 2: return const ModsPage();
      case 3: return const ImportPage();
      case 4: return const AiPage();
      case 5: return const LogsPage();
      case 6: return const SettingsPage();
      default: return const HomePage();
    }
  }
}
