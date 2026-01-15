import 'dart:io';
import 'package:path/path.dart' as p;

class InstalledMod {
  final String fileName;
  final String filePath;
  bool isEnabled;

  InstalledMod({required this.fileName, required this.filePath, this.isEnabled = true});
}

class ModService {
  final String gameDir;

  ModService(this.gameDir);
  
  String get _modsFolder => p.join(gameDir, 'Mods');

  Future<List<InstalledMod>> getInstalledMods() async {
    final dir = Directory(_modsFolder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return [];
    }
    
    final List<InstalledMod> mods = [];
    await for (final file in dir.list()) {
      if (file is File) {
        final name = p.basename(file.path);
        if (name.toLowerCase().endsWith('.jar') || name.toLowerCase().endsWith('.zip')) {
          mods.add(InstalledMod(fileName: name, filePath: file.path, isEnabled: true));
        } else if (name.toLowerCase().endsWith('.disabled')) {
          mods.add(InstalledMod(fileName: name, filePath: file.path, isEnabled: false));
        }
      }
    }
    return mods;
  }

  Future<void> toggleMod(InstalledMod mod) async {
    final File file = File(mod.filePath);
    if (!await file.exists()) return;
    
    String newPath;
    if (mod.isEnabled) {
       newPath = "${mod.filePath}.disabled";
    } else {
       newPath = mod.filePath.replaceAll(".disabled", "");
    }
    
    await file.rename(newPath);
    mod.isEnabled = !mod.isEnabled;
  }
  
  Future<void> deleteMod(InstalledMod mod) async {
      final file = File(mod.filePath);
      if (await file.exists()) await file.delete();
  }
}
