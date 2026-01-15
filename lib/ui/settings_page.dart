import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
        child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24)
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("LAUNCHER SETTINGS", style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    const SizedBox(height: 32),
                    Text("MAX RAM (MB)", style: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _ramController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            suffixText: "MB",
                            suffixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                    ),
                    const SizedBox(height: 24),
                    Text("LAUNCH FLAGS", style: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _flagsController,
                        decoration: const InputDecoration(
                            hintText: "--option value",
                        ),
                    ),
                    const SizedBox(height: 24),
                    Text("INTERFACE FRAME RATE (HZ)", style: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownMenu<int>(
                        initialSelection: _fps,
                        expandedInsets: EdgeInsets.zero,
                        dropdownMenuEntries: [60, 120, 144, 165, 200].map((e) => DropdownMenuEntry(value: e, label: "$e Hz")).toList(),
                        onSelected: (v) => setState(() => _fps = v ?? 60),
                    ),
                    
                    const SizedBox(height: 32),
                    Text("DANGER ZONE", style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.error)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.3),
                        border: Border.all(color: colorScheme.error.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: colorScheme.error),
                        title: Text("RESET LAUNCHER", style: GoogleFonts.roboto(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text("Wipe all data (Config, UserData, Cache)", style: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant, fontSize: 10)),
                        trailing: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("RESET LAUNCHER?", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                                content: Text("This will delete ALL launcher data, including settings, saved accounts, and caches.\nThis cannot be undone.", style: GoogleFonts.roboto()),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                    onPressed: () => Navigator.pop(ctx, true), 
                                    child: const Text("RESET EVERYTHING")
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final launcher = context.read<GameLauncher>();
                              await launcher.resetLauncher();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Launcher Reset. Please restart app.")),
                                );
                              }
                            }
                          },
                          child: const Text("RESET"),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            onPressed: _saveSettings,
                            child: Text("SAVE SETTINGS", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16))
                        )
                    )
                ],
            )
          )
        )
    );
  }
}
