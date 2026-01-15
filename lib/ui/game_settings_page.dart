import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/ui/shaders_page.dart';
import 'package:hyta_launcher/services/shader_service.dart';
import 'package:hyta_launcher/services/patch_service.dart';
import 'package:hyta_launcher/services/game_config_service.dart';
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
  late GameConfigService _configService;
  String _statusMessage = "";
  bool _isBusy = false;
  final TextEditingController _onlineUrlCtrl = TextEditingController();
  final TextEditingController _ruUrlCtrl = TextEditingController();
  final TextEditingController _configCtrl = TextEditingController();
  bool _configLoading = true;
  @override
  void initState() {
    super.initState();
    _initServices();
  }
  Future<void> _initServices() async {
    final home = Platform.environment['HOME'] ?? '/';
    final shareDir = p.join(home, '.local', 'share');
    final gamePath = p.join(shareDir, 'Hytale', 'install', 'release', 'package', 'game', 'latest');
    final userDataDir = p.join(shareDir, 'HyTaLauncher', 'UserData');
    final cacheDir = p.join(userDataDir, 'cache');  
    _patchService = PatchService(gamePath, cacheDir);
    _shaderService = ShaderService(gamePath, userDataDir);
    _configService = GameConfigService(userDataDir);
    String online = await _patchService.getUrl(PatchService.PREF_ONLINE_URL);
    if (online.isEmpty) online = PatchService.DEFAULT_ONLINE_URL;
    _onlineUrlCtrl.text = online;
    String ru = await _patchService.getUrl(PatchService.PREF_RU_URL);
    if (ru.isEmpty) ru = PatchService.DEFAULT_RU_URL;
    _ruUrlCtrl.text = ru;
    try {
      String configContent = await _configService.readConfig();
      _configCtrl.text = configContent;
    } catch (e) {
      _configCtrl.text = "https://hytale-services.vercel.app/api/patch";
    } finally {
      if (mounted) setState(() => _configLoading = false);
    }
  }
  Future<void> _saveUrl(String key, String value) async {
      await _patchService.setUrl(key, value);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("URL Saved")));
  }
  Future<void> _installOnlineFix() async {
      setState(() { _isBusy = true; _statusMessage = "Applying Online Fix (Local)..."; });
      try {
          final launcher = context.read<GameLauncher>();
          await launcher.applyOnlineFix();
          setState(() { _isBusy = false; _statusMessage = "Online Fix Applied!"; });
          if(mounted) _showSuccess("Online Fix applied using local files.");
      } catch (e) {
          setState(() { _isBusy = false; _statusMessage = "Error: $e"; });
          _showError("Failed to apply fix: $e");
      }
  }
  Future<void> _installRussifier() async {
      _runPatchOperation("Russifier", _ruUrlCtrl.text, "russifier");
  }
  Future<void> _runPatchOperation(String name, String url, String cacheName) async {
       if (url.isEmpty || url.contains("PUT_URL_HERE")) {
           _showError("$name URL is missing! Please paste the link in the field above.");
           return;
       }
       setState(() { _isBusy = true; _statusMessage = "Starting $name..."; });
       try {
           await _patchService.installPatch(url, cacheName, (status) {
               setState(() => _statusMessage = status);
           });
           setState(() { _isBusy = false; _statusMessage = "$name Installed Successfully!"; });
           if(mounted) _showSuccess("$name Installed!");
       } catch (e) {
           setState(() { _isBusy = false; _statusMessage = "Error: $e"; });
           _showError("Failed to install $name: $e");
           if (e.toString().contains("404")) {
               _showError("Link seems broken (404). Try 'FIND LINK'.");
           }
       }
  }
  Future<void> _saveConfig() async {
    setState(() { _isBusy = true; _statusMessage = "Saving Config..."; });
    try {
      await _configService.saveConfig(_configCtrl.text);
      setState(() { _isBusy = false; _statusMessage = "Config Saved!"; });
      if(mounted) _showSuccess("Configuration saved successfully.");
    } catch (e) {
      setState(() { _isBusy = false; _statusMessage = "Error saving config: $e"; });
      _showError("Could not save config: $e");
    }
  }
  void _showSuccess(String msg) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("SUCCESS", style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold, color: Colors.green)),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]
      ));
  }
  void _showError(String msg) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("ERROR", style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]
      ));
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
               Tab(text: LocalizationService().get("tools.title") ?? "TOOLS"),
               const Tab(text: "SHADERS"),
               const Tab(text: "CONFIG"),
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
                              _patchTile(LocalizationService().get("tools.onlinefix"), "Play with friends", Icons.wifi, 
                                  () => _installOnlineFix(), _onlineUrlCtrl, PatchService.PREF_ONLINE_URL),
                              const SizedBox(height: 16),
                              _patchTile(LocalizationService().get("tools.russifier"), "Russian Language", Icons.language, 
                                  () => _installRussifier(), _ruUrlCtrl, PatchService.PREF_RU_URL),
                          ]
                      )
                   ),
                   const ShadersPage(),
                   _configLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _configCtrl,
                                  maxLines: null,
                                  expands: true,
                                  style: GoogleFonts.robotoMono(fontSize: 13, color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: "Config JSON...",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: _saveConfig,
                                  icon: const Icon(Icons.save),
                                  label: const Text("SAVE CONFIG")
                                )
                              )
                            ],
                          )
                      )
               ],
            ),
          ),
          if (_statusMessage.isNotEmpty)
             Container(
               margin: const EdgeInsets.all(16),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.white24),
                 color: const Color(0xFF101010)
               ),
               child: Row(
                 children: [
                   const Icon(Icons.info_outline, color: Colors.white),
                   const SizedBox(width: 12),
                   Text("STATUS: ", style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold, color: Colors.white54)),
                   Expanded(child: Text(_statusMessage, style: const TextStyle(color: Colors.white))),
                 ],
               ),
             ),
        ],
      ),
    );
  }
  Future<void> _openSearch(String query) async {
      try {
          await Process.run('xdg-open', ["https://google.com/search?q=$query"]);
      } catch (e) {
          _showError("Could not open browser: $e");
      }
  }
  Widget _patchTile(String title, String subtitle, IconData icon, VoidCallback onTap, TextEditingController ctrl, String key) {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF050505),
              border: Border.all(color: Colors.white12)
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                  Icon(icon, size: 24, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      Text(subtitle, style: const TextStyle(color: Colors.white54)),
                  ])),
                  OutlinedButton(
                    onPressed: () => _openSearch("Hytale $title download"), 
                    child: const Text("FIND LINK")
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _isBusy ? null : onTap, child: const Text("INSTALL")),
              ]),
              const SizedBox(height: 16),
              Text("DIRECT DOWNLOAD URL:", style: GoogleFonts.getFont('Doto', color: Colors.white24, fontSize: 10)),
              const SizedBox(height: 8),
              TextField(
                  controller: ctrl,
                  onChanged: (val) => _saveUrl(key, val),
                  decoration: const InputDecoration(
                     hintText: "Paste .zip URL here",
                     isDense: true,
                  ),
              )
          ])
      );
  }
}
