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
                           _navButton("MODS", 1),
                           _navButton("IMPORT", 2),
                           const Spacer(),
                           _navButton("LOGS", 3),
                           _navButton("SETTINGS", 4),
                           const SizedBox(height: 20),
                       ]
                   ),
                ),

                Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: IndexedStack(
                          index: _currentIndex,
                          children: [
                               const HomePage(),
                               const ModsPage(), 
                               const ImportPage(),
                               const LogsPage(),
                               const SettingsPage(),
                          ],
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
}
