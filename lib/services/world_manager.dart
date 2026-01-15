import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

class WorldInfo {
  final String name;
  final String path;
  final DateTime? lastModified;
  final int? sizeBytes;
  
  WorldInfo({
    required this.name,
    required this.path,
    this.lastModified,
    this.sizeBytes,
  });
}

class WorldManager extends ChangeNotifier {
  final String _universeDir;
  List<WorldInfo> _worlds = [];
  bool _isLoading = false;
  String? _error;
  
  WorldManager({required String gameDir})
      : _universeDir = p.join(gameDir, 'universe', 'worlds');
  
  List<WorldInfo> get worlds => List.unmodifiable(_worlds);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get universePath => _universeDir;
  String get gameDir => _universeDir;
  
  Future<void> refreshWorlds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final dir = Directory(_universeDir);
      if (!await dir.exists()) {
        _worlds = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final List<WorldInfo> foundWorlds = [];
      
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          final stat = await entity.stat();
          
          int totalSize = 0;
          await for (final file in entity.list(recursive: true)) {
            if (file is File) {
              totalSize += await file.length();
            }
          }
          
          foundWorlds.add(WorldInfo(
            name: name,
            path: entity.path,
            lastModified: stat.modified,
            sizeBytes: totalSize,
          ));
        }
      }
      
      foundWorlds.sort((a, b) => (b.lastModified ?? DateTime(0)).compareTo(a.lastModified ?? DateTime(0)));
      
      _worlds = foundWorlds;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteWorld(String name) async {
    try {
      final worldPath = p.join(_universeDir, name);
      final dir = Directory(worldPath);
      
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await refreshWorlds();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete world: $e';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> exportWorld(String name, String outputPath) async {
    try {
      final worldPath = p.join(_universeDir, name);
      final dir = Directory(worldPath);
      
      if (!await dir.exists()) {
        _error = 'World not found: $name';
        notifyListeners();
        return false;
      }
      
      final archive = Archive();
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: worldPath);
          final data = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, data.length, data));
        }
      }
      
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await File(outputPath).writeAsBytes(zipData);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to export world: $e';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> importWorld(String zipPath, {String? customName}) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        _error = 'Zip file not found: $zipPath';
        notifyListeners();
        return false;
      }
      
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final worldName = customName ?? p.basenameWithoutExtension(zipPath);
      final worldPath = p.join(_universeDir, worldName);
      
      final worldDir = Directory(worldPath);
      if (await worldDir.exists()) {
        _error = 'World already exists: $worldName';
        notifyListeners();
        return false;
      }
      
      await worldDir.create(recursive: true);
      
      for (final file in archive) {
        final filePath = p.join(worldPath, file.name);
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
      
      await refreshWorlds();
      return true;
    } catch (e) {
      _error = 'Failed to import world: $e';
      notifyListeners();
      return false;
    }
  }
  
  Future<void> openWorldFolder(String name) async {
    final worldPath = p.join(_universeDir, name);
    if (Platform.isLinux) {
      await Process.run('xdg-open', [worldPath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [worldPath]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [worldPath]);
    }
  }
  
  String getWorldPath(String name) => p.join(_universeDir, name);
  
  String formatSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
