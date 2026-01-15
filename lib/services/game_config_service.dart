
import 'dart:io';
import 'package:path/path.dart' as p;

class GameConfigService {
  final String _userDataDir;
  
  GameConfigService(this._userDataDir);

  Future<File> get _configFile async {
    return File(p.join(_userDataDir, "Settings.json"));
  }

  Future<String> readConfig() async {
    final file = await _configFile;
    if (await file.exists()) {
      return await file.readAsString();
    }
    return "";
  }

  Future<void> saveConfig(String content) async {
    final file = await _configFile;
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }
}
