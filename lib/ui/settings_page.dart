import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hyta_launcher/services/localization_service.dart';
import 'package:hyta_launcher/services/game_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ramController = TextEditingController();
  final TextEditingController _flagsController = TextEditingController();
  int _fps = 60;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ramController.text = prefs.getString('max_ram') ?? "4096";
    _flagsController.text = prefs.getString('custom_flags') ?? "";
    setState(() {
        _fps = prefs.getInt('launcher_fps') ?? 60;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('max_ram', _ramController.text);
    await prefs.setString('custom_flags', _flagsController.text);
    await prefs.setInt('launcher_fps', _fps);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                color: const Color(0xFF101010),

            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("LAUNCHER SETTINGS", style: GoogleFonts.getFont('Doto', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 32),
                    Text("MAX RAM (MB)", style: GoogleFonts.getFont('Doto', color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _ramController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            suffixText: "MB",
                            suffixStyle: TextStyle(color: Colors.white54)
                        ),
                    ),
                    const SizedBox(height: 24),
                    Text("LAUNCH FLAGS", style: GoogleFonts.getFont('Doto', color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _flagsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            hintText: "--option value",
                            hintStyle: TextStyle(color: Colors.white24)
                        ),
                    ),
                    const SizedBox(height: 24),
                    Text("LANGUAGE / ЯЗЫК", style: GoogleFonts.getFont('Doto', color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                        value: LocalizationService().currentLang,
                        dropdownColor: const Color(0xFF000000),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(filled: true, fillColor: Color(0xFF101010)),
                        items: const [
                            DropdownMenuItem(value: "en", child: Text("English")),
                            DropdownMenuItem(value: "ru", child: Text("Русский")),
                        ],
                        onChanged: (v) async {
                             if (v != null) {
                                 await LocalizationService().loadLanguage(v);
                                 setState(() {});
                             }
                        },
                    ),

                    const SizedBox(height: 24),
                    Text("INTERFACE FRAME RATE (HZ)", style: GoogleFonts.getFont('Doto', color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                        value: _fps,
                        dropdownColor: const Color(0xFF000000),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(filled: true, fillColor: Color(0xFF101010), suffixText: "Hz"),
                        items: const [60, 122, 144, 165, 200].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                        onChanged: (v) => setState(() => _fps = v ?? 60),
                    ),
                    
                    const SizedBox(height: 24),

                    Text("PATCHER (WIP)", style: GoogleFonts.getFont('Doto', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        title: Text("APPLY PATCHER (WIP)", style: GoogleFonts.getFont('Doto', color: Colors.white, fontSize: 14)),
                        subtitle: Text("Patches server for LAN/Offline", style: GoogleFonts.getFont('Doto', color: Colors.white38, fontSize: 10)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                            foregroundColor: Colors.blueAccent,
                             shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () async {
                             final launcher = context.read<GameLauncher>();
                             if (await launcher.isOnlineFixAvailable()) {
                                await launcher.applyOnlineFix();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Patcher Applied. Check logs.")),
                                  );
                                }
                             } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Fix Source not found!")),
                                  );
                                }
                             }
                          },
                          child: const Text("INSTALL"),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF0000),
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(vertical: 20)
                            ),
                            onPressed: _saveSettings,
                            child: Text("SAVE SETTINGS", style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold))
                        )
                    )
                ],
            )
          )
        )
    );
  }
}
