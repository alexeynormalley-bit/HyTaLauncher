import 'package:hyta_launcher/ui/textures_page.dart';
import 'dart:io';
import 'package:hyta_launcher/services/server_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/ui/shaders_page.dart';
import 'package:hyta_launcher/services/shader_service.dart';
import 'package:hyta_launcher/services/patch_service.dart';
import 'package:hyta_launcher/services/localization_service.dart';
import 'package:hyta_launcher/services/game_launcher.dart';
import 'package:path/path.dart' as p;

class GameSettingsPage extends StatefulWidget {
  const GameSettingsPage({super.key});
  @override
  State<GameSettingsPage> createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  late PatchService _patchService;
  late ShaderService _shaderService;
  String _statusMessage = "";
  bool _isBusy = false;

  String _gamePath = "";
  String _backupDir = "";
  bool _hasBackup = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }
  
  Future<void> _initServices() async {
    final home = Platform.environment['HOME'] ?? '/';
    final shareDir = p.join(home, '.local', 'share');
    final gamePath = p.join(shareDir, 'Hytale', 'install', 'release', 'package', 'game', 'latest');
    _gamePath = gamePath;
    final userDataDir = p.join(shareDir, 'HyTaLauncher', 'UserData');
    _backupDir = p.join(userDataDir, 'backups', 'russifier');
    _checkBackup();

    final cacheDir = p.join(userDataDir, 'cache');  
    _patchService = PatchService(gamePath, cacheDir);
    _shaderService = ShaderService(gamePath, userDataDir);
    if (mounted) setState(() {});
  }

  Future<void> _checkBackup() async {
    final exists = await Directory(_backupDir).exists();
    if (mounted) setState(() => _hasBackup = exists);
  }

  Future<void> _installRussifier() async {
      setState(() { _isBusy = true; _statusMessage = "Installing Russifier..."; });
      
      try {
        final sourceDir = Directory('/home/matvelo/Загрузки/Hytale-Russian_v1.1.0/install/release/package/game/latest');
        if (!await sourceDir.exists()) {
           throw "Russifier source not found at ${sourceDir.path}";
        }
        
        final destDir = Directory(_gamePath);
        if (!await destDir.exists()) {
            throw "Game directory not found. Install game first.";
        }

        if (!_hasBackup) {
           final dataDir = Directory(p.join(_gamePath, 'Client', 'Data'));
           if (await dataDir.exists()) {
               setState(() => _statusMessage = "Creating Backup...");
               await _copyRecursive(dataDir, Directory(_backupDir));
               await _checkBackup();
           }
        }
        
        setState(() => _statusMessage = "Copying Files...");
        await _copyRecursive(sourceDir, destDir);
        
        setState(() { _isBusy = false; _statusMessage = "Russifier Installed!"; });
        if(mounted) _showSuccess("Russifier installed successfully.");
      } catch (e) {
         setState(() { _isBusy = false; _statusMessage = "Error: $e"; });
         _showError("Failed to install Russifier: $e");
      }
  }

  Future<void> _restoreRussifier() async {
      if (!_hasBackup) return;
      setState(() { _isBusy = true; _statusMessage = "Restoring Backup..."; });
      try {
          final backupSource = Directory(_backupDir);
          final destDataDir = Directory(p.join(_gamePath, 'Client', 'Data'));
          
          if (await destDataDir.exists()) {
              await destDataDir.delete(recursive: true);
          }
          await destDataDir.create(recursive: true);

          await _copyRecursive(backupSource, destDataDir);
          await backupSource.delete(recursive: true);
          await _checkBackup();

          setState(() { _isBusy = false; _statusMessage = "Restored Original Files!"; });
          if(mounted) _showSuccess("Original language files restored.");
      } catch (e) {
          setState(() { _isBusy = false; _statusMessage = "Error: $e"; });
          _showError("Failed to restore: $e");
      }
  }

  Future<void> _copyRecursive(Directory source, Directory dest) async {
    if (!await dest.exists()) {
      await dest.create(recursive: true);
    }
    
    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final newPath = p.join(dest.path, name);
      if (entity is Directory) {
        await _copyRecursive(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  void _showSuccess(String msg) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("SUCCESS", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.green)),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(color: Colors.white)))]
      ));
  }
  
  void _showError(String msg) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("ERROR", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(color: Colors.white)))]
      ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalizationService(),
      builder: (context, _) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.roboto(),
            indicatorColor: Colors.white,
            tabs: [
               Tab(text: LocalizationService().get("tools.title") ?? "RuLang"),
               const Tab(text: "SHADERS"),
               const Tab(text: "TEXTURES"),
            ]
          ),
          Expanded(
            child: TabBarView(
               children: [
                   SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(color: Colors.white12),
                                  borderRadius: BorderRadius.circular(16)
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.language, size: 24, color: Colors.white),
                                        const SizedBox(width: 16),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(LocalizationService().get("tools.title") ?? "RuLang", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                            const Text("Changes only Russian language", style: TextStyle(color: Colors.white54)),
                                        ])),
                                        if (_hasBackup) ...[
                                            OutlinedButton(
                                                onPressed: _isBusy ? null : _restoreRussifier,
                                                style: OutlinedButton.styleFrom(foregroundColor: Colors.white), 
                                                child: const Text("RESTORE")
                                            ),
                                            const SizedBox(width: 8),
                                        ],
                                        ElevatedButton(
                                            onPressed: _isBusy ? null : _installRussifier, 
                                            child: const Text("INSTALL")
                                        ),
                                    ]),
                                  ],
                                )
                              )
                          ]
                      )
                   ),
                   const ShadersPage(),
                   const TexturesPage(),
               ],
            ),
          ),
          if (_statusMessage.isNotEmpty)
             Container(
               margin: const EdgeInsets.all(16),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.white24),
                 color: const Color(0xFF101010),
                 borderRadius: BorderRadius.circular(12)
               ),
               child: Row(
                 children: [
                   const Icon(Icons.info_outline, color: Colors.white),
                   const SizedBox(width: 12),
                   Text("STATUS: ", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.white54)),
                   Expanded(child: Text(_statusMessage, style: const TextStyle(color: Colors.white))),
                 ],
               ),
             ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildServerControlTile() {
    return Consumer<ServerManager>(
      builder: (context, serverManager, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(16)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   const Icon(Icons.storage, size: 24, color: Colors.white),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("SERVER CONTROLS", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                         Text(serverManager.isRunning ? "RUNNING ON PORT ${serverManager.serverPort}" : "STOPPED", 
                             style: TextStyle(color: serverManager.isRunning ? Colors.green : Colors.white54)),
                       ],
                     ),
                   ),
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: serverManager.isRunning ? Colors.white : Colors.black,
                       foregroundColor: serverManager.isRunning ? Colors.black : Colors.white,
                       side: const BorderSide(color: Colors.white)
                     ),
                     onPressed: () async {
                       if (serverManager.isRunning) {
                         await serverManager.stopServer();
                       } else {
                         await serverManager.startServer();
                       }
                     }, 
                     child: Text(serverManager.isRunning ? "STOP" : "START")
                   ),
                 ],
               ),
            ],
          ),
        );
      }
    );
  }
}
