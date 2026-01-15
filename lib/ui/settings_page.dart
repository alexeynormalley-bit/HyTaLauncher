
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ramController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ramController.text = prefs.getString('max_ram') ?? "4096";
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('max_ram', _ramController.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                color: Colors.black 
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text("LAUNCHER SETTINGS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text("MAX RAM (MB)", style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _ramController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixText: "MB"
                        ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: _saveSettings,
                            child: const Text("SAVE")
                        )
                    )
                ],
            )
        )
    );
  }
}
