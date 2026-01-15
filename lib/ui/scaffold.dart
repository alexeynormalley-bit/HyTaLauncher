
import 'package:flutter/material.dart';
import 'package:hyta_launcher/ui/home_page.dart';
import 'package:hyta_launcher/ui/mods_page.dart';
import 'package:hyta_launcher/ui/home_page.dart';
import 'package:hyta_launcher/ui/mods_page.dart';
import 'package:hyta_launcher/ui/import_page.dart';
import 'package:hyta_launcher/ui/settings_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Window Title Bar (Custom)
          Container(
            height: 40,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Text("HYTA LAUNCHER", 
                   style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(width: 32),
                TextButton(
                    onPressed: () => setState(() => _currentIndex = 0),
                    child: Text("PLAY", 
                        style: TextStyle(
                            color: _currentIndex == 0 ? Colors.white : Colors.white54, 
                            fontWeight: FontWeight.bold))
                ),
                TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text("MODS", 
                         style: TextStyle(
                            color: _currentIndex == 1 ? Colors.white : Colors.white54, 
                            fontWeight: FontWeight.bold))
                ),
                TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: Text("IMPORT", 
                         style: TextStyle(
                            color: _currentIndex == 2 ? Colors.white : Colors.white54, 
                            fontWeight: FontWeight.bold))
                ),
                TextButton(
                    onPressed: () => setState(() => _currentIndex = 3),
                    child: Text("SETTINGS", 
                         style: TextStyle(
                            color: _currentIndex == 3 ? Colors.white : Colors.white54, 
                            fontWeight: FontWeight.bold))
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => Navigator.of(context).maybePop(), 
                  splashRadius: 20,
                )
              ],
            ),
          ),
          Expanded(
              child: IndexedStack(
                  index: _currentIndex,
                  children: [
                       HomePage(),
                       ModsPage(), // Not const, allows state updates if we change parent
                       ImportPage(),
                       SettingsPage(), // Added SettingsPage
                  ],
              )
          ),
        ],
      ),
    );
  }
}
