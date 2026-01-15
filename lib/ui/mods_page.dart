import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/mod_service.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ModsPage extends StatefulWidget {
  const ModsPage({super.key});

  @override
  State<ModsPage> createState() => _ModsPageState();
}

class _ModsPageState extends State<ModsPage> {
  List<InstalledMod> _installedMods = [];
  bool _isLoading = false;
  
  ModService? _modService;

  @override
  void initState() {
    super.initState();
    _initService();
  }
  
  Future<void> _initService() async {
      final home = const String.fromEnvironment('HOME') != "" 
          ? const String.fromEnvironment('HOME') 
          : Platform.environment['HOME'] ?? '/';
      final startDir = p.join(home, '.local', 'share', 'HyTaLauncher', 'UserData');
      
      _modService = ModService(startDir);
      _loadInstalled();
  }
  
  Future<void> _loadInstalled() async {
      if (_modService == null) return;
      setState(() => _isLoading = true);
      try {
          final mods = await _modService!.getInstalledMods();
          setState(() {
              _installedMods = mods;
          });
      } finally {
          setState(() => _isLoading = false);
      }
  }

  Future<void> _delete(InstalledMod mod) async {
       await _modService?.deleteMod(mod);
       _loadInstalled();
  }
  
  Future<void> _toggle(InstalledMod mod) async {
      await _modService?.toggleMod(mod);
      _loadInstalled();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
          Expanded(
              child: Container(
                  decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white24))
                  ),
                  child: Column(
                      children: [
                          Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                      Text("INSTALLED MODS", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                                      IconButton(
                                          icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
                                          onPressed: _loadInstalled,
                                          tooltip: "Refresh List",
                                      )
                                  ],
                              ),
                          ),
                          Expanded(
                              child: _isLoading 
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                                  : ListView.separated(
                                  separatorBuilder: (c, i) => const Divider(color: Colors.white10, height: 1),
                                  itemCount: _installedMods.length,
                                  itemBuilder: (context, index) {
                                      final mod = _installedMods[index];
                                      return ListTile(
                                          title: Text(mod.fileName, 
                                              style: TextStyle(
                                                  decoration: mod.isEnabled ? null : TextDecoration.lineThrough,
                                                  color: mod.isEnabled ? Colors.white : Colors.white24,
                                                  fontFamily: GoogleFonts.roboto().fontFamily
                                              ),
                                              overflow: TextOverflow.ellipsis
                                          ),
                                          leading: Checkbox(
                                              value: mod.isEnabled,
                                              activeColor: Colors.white,
                                              checkColor: Colors.black,
                                              side: const BorderSide(color: Colors.white54),
                                              onChanged: (v) => _toggle(mod),
                                          ),
                                          trailing: IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white54),
                                              onPressed: () => _delete(mod),
                                          ),
                                          onTap: () => _toggle(mod),
                                      );
                                  }
                              )
                          )
                      ],
                  )
              )
          ),
      ],
    );
  }
}
