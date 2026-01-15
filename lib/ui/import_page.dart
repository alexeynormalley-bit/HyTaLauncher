import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String _status = "";
  bool _isImporting = false;

  Future<void> _importMods() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Mod Files',
      extensions: <String>['jar', 'zip'],
    );
    
    final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (files.isEmpty) return;

    setState(() {
      _isImporting = true;
      _status = "Importing ${files.length} files...";
    });

    try {
      final home = const String.fromEnvironment('HOME') != "" 
          ? const String.fromEnvironment('HOME') 
          : Platform.environment['HOME'] ?? '/';
      final modsDir = Directory(p.join(home, '.local', 'share', 'HyTaLauncher', 'UserData', 'Mods'));
      
      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }

      for (final file in files) {
         final filename = file.name;
         final dest = p.join(modsDir.path, filename);
         await File(file.path).copy(dest);
      }

      setState(() => _status = "Successfully imported ${files.length} mods!");
    } catch (e) {
      setState(() => _status = "Error importing: $e");
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.drive_folder_upload, size: 64, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            "MANUAL MOD IMPORT",
            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select .jar or .zip files to add to your mods folder",
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _importMods,
            icon: const Icon(Icons.add),
            label: Text("SELECT FILES", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.white,
               foregroundColor: Colors.black,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          if (_status.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Text(_status, style: const TextStyle(color: Colors.white)),
            )
        ],
      ),
    );
  }
}
