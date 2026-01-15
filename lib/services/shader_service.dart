import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

class ShaderService {
  final String _gameDir;
  final String _userDataDir;
  
  ShaderService(this._gameDir, this._userDataDir);
  
  String get _shaderTexturesDir => p.join(_gameDir, 'Client', 'Data', 'Game', 'ShaderTextures');
  String get _settingsFile => p.join(_userDataDir, 'Settings.json');
  

  
  Future<List<File>> getShaderTextures() async {
    final dir = Directory(_shaderTexturesDir);
    if (!await dir.exists()) return [];
    
    return dir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
  }
  
  Future<void> replaceTexture(String fileName, String newPath) async {
    final target = File(p.join(_shaderTexturesDir, fileName));
    if (!await target.exists()) return;
    

    final backup = File("${target.path}.bak");
    if (!await backup.exists()) {
       await target.copy(backup.path);
    }
    
    await File(newPath).copy(target.path);
  }
  
  Future<void> resetTexture(String fileName) async {
     final target = File(p.join(_shaderTexturesDir, fileName));
     final backup = File("${target.path}.bak");
     
     if (await backup.exists()) {
       await backup.copy(target.path);
       await backup.delete();
     }
  }
  
  bool hasBackup(String fileName) {
     return File(p.join(_shaderTexturesDir, "$fileName.bak")).existsSync();
  }


  
  Future<Map<String, dynamic>> getRenderingSettings() async {
      final file = File(_settingsFile);
      if (!await file.exists()) return {};
      
      try {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          return json['RenderingSettings'] ?? {};
      } catch (e) {
          return {};
      }
  }
  
  Future<void> saveRenderingSettings(Map<String, dynamic> newSettings) async {
      final file = File(_settingsFile);
      if (!await file.exists()) return;
      
      try {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          
          json['RenderingSettings'] = newSettings;
          
          await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
      } catch (e) {
          print("Error saving settings: $e");
      }
  }


  
  Future<void> exportPreset(String path, String name, Map<String, dynamic> settings) async {
      final file = File(path);
      final preset = {
          "name": name,
          "description": "Custom Shader Config for Hytale Launcher",
          "settings": settings
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(preset));
  }
  
  Future<void> importPreset(String path) async {
      final file = File(path);
      if (!await file.exists()) return;
      
      final content = await file.readAsString();
      final json = jsonDecode(content);
      
      if (json.containsKey('settings')) {
          await saveRenderingSettings(json['settings']);
      }
  }
}
