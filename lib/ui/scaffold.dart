import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/localization_service.dart';
import 'package:hyta_launcher/ui/home_page.dart';
import 'package:hyta_launcher/ui/mods_page.dart';
import 'package:hyta_launcher/ui/import_page.dart';
import 'package:hyta_launcher/ui/game_settings_page.dart';
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [

          Container(
             height: 50,
             decoration: const BoxDecoration(
               border: Border(bottom: BorderSide(color: Colors.white24))
             ),
             padding: const EdgeInsets.symmetric(horizontal: 16),
             child: Row(
               children: [
                 Text(LocalizationService().get("app.title") ?? "HYTALAUNCHER", 
                   style: GoogleFonts.getFont('Doto', color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                 ),
                 const Spacer(),
                 IconButton(
                   icon: const Icon(Icons.close, color: Colors.white), 
                   onPressed: () => exit(0),
                   tooltip: "Close",
                 )
               ],
             ),
          ),
          
          Expanded(
            child: Row(
              children: [

                Container(
                   width: 250,
                   decoration: const BoxDecoration(
                       color: Colors.black,
                       border: Border(right: BorderSide(color: Colors.white24))
                   ),
                   child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                           const SizedBox(height: 20),
                           _navButton("PLAY", 0),
                           _navButton("WORLDS", 1),
                           _navButton("MODS", 2),
                           _navButton("IMPORT", 3),
                           const Spacer(),
                           _navButton("AI [alpha]", 4), 
                           _navButton("LOGS", 5),
                           _navButton("SETTINGS", 6),
                           const SizedBox(height: 20),
                       ]
                   ),
                ),

                Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
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
                    )
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String label, int index) {
      final isSelected = _currentIndex == index;
      final color = isSelected ? const Color(0xFFFF0000) : Colors.white;
      
      return InkWell(
        onTap: () => setState(() => _currentIndex = index),
        hoverColor: const Color(0xFF101010),
        child: Container(
           height: 50,
           padding: const EdgeInsets.symmetric(horizontal: 24),
           decoration: BoxDecoration(
             border: isSelected ? const Border(left: BorderSide(color: Color(0xFFFF0000), width: 4)) : null
           ),
           alignment: Alignment.centerLeft,
           child: Text(
             label, 
             style: GoogleFonts.getFont('Doto',
                 color: color, 
                 fontWeight: FontWeight.bold,
                 fontSize: 16
             )
           ),
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
