
import 'package:flutter/material.dart';
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
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                      const Text("INSTALLED MODS", style: TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                          icon: const Icon(Icons.refresh, size: 16),
                                          onPressed: _loadInstalled,
                                          tooltip: "Refresh List",
                                      )
                                  ],
                              ),
                          ),
                          Expanded(
                              child: _isLoading 
                                  ? const Center(child: CircularProgressIndicator()) 
                                  : ListView.builder(
                                  itemCount: _installedMods.length,
                                  itemBuilder: (context, index) {
                                      final mod = _installedMods[index];
                                      return ListTile(
                                          title: Text(mod.fileName, 
                                              style: TextStyle(
                                                  decoration: mod.isEnabled ? null : TextDecoration.lineThrough,
                                                  color: mod.isEnabled ? Colors.white : Colors.white24
                                              ),
                                              overflow: TextOverflow.ellipsis
                                          ),
                                          trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                  IconButton(
                                                      icon: Icon(mod.isEnabled ? Icons.check_box : Icons.check_box_outline_blank),
                                                      onPressed: () => _toggle(mod),
                                                  ),
                                                  IconButton(
                                                      icon: const Icon(Icons.delete, size: 16),
                                                      onPressed: () => _delete(mod),
                                                  )
                                              ],
                                          ),
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
