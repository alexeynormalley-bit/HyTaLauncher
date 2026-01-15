import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class TextureManager extends ChangeNotifier {
  final String _gameDir;
  final List<File> _textureFiles = [];
  bool _isLoading = false;

  TextureManager(this._gameDir);

  List<File> get textureFiles => List.unmodifiable(_textureFiles);
  bool get isLoading => _isLoading;

  String get _assetsDir => p.join(_gameDir, 'Assets');

  Future<void> scanTextures() async {
    _isLoading = true;
    notifyListeners();
    _textureFiles.clear();

    final root = Directory(_assetsDir);
    if (!await root.exists()) {
      final zipFile = File(p.join(_gameDir, 'Assets.zip'));
      if (await zipFile.exists()) {
        try {
          // Extract Assets.zip
          await _extractAssets(zipFile, root);
        } catch (e) {
          print("Error extracting Assets.zip: $e");
          _isLoading = false;
          notifyListeners();
          return;
        }
      } else {
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          // Filter for common texture formats
          if (['.png', '.jpg', '.jpeg', '.tga', '.bmp'].contains(ext)) {
            _textureFiles.add(entity);
          }
        }
      }
    } catch (e) {
      print("Error scanning textures: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _extractAssets(File zipFile, Directory targetDir) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // If target doesn't exist, create it
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(p.join(targetDir.path, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(p.join(targetDir.path, filename)).create(recursive: true);
      }
    }
  }

  Future<void> replaceTexture(File target, String newImagePath) async {
    if (!await target.exists()) return;

    // Create backup if not exists
    final backup = File("${target.path}.bak");
    if (!await backup.exists()) {
      await target.copy(backup.path);
    }

    await File(newImagePath).copy(target.path);
    scanTextures(); // Refresh to potentially show updates (though file obj is same)
  }

  Future<void> restoreBackup(File target) async {
    final backup = File("${target.path}.bak");
    if (await backup.exists()) {
      await backup.copy(target.path);
      await backup.delete(); // Remove backup after restore? Or keep it? keeping is safer but user might want "reset".
      // Let's keep it simple: Restore means go back to original. 
      // If we delete backup, next replace becomes "new original". 
      // User requested "restore", usually means "undo changes".
    }
  }

  Future<bool> hasBackup(File target) async {
    return await File("${target.path}.bak").exists();
  }

  Future<void> importTexturePack(String zipPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
           // Try to match file structure relative to Assets
           // If zip has "textures/block/stone.png", we look for "$_assetsDir/textures/block/stone.png"
           // We'll try to find a match in our scanned files (or just path check)
           
           final potentialPath = p.join(_assetsDir, file.name);
           final targetFile = File(potentialPath);
           
           // Only replace if target exists (don't add random garbage)
           if (await targetFile.exists()) {
               final backup = File("$potentialPath.bak");
               if (!await backup.exists()) {
                   await targetFile.copy(backup.path);
               }
               
               final outputStream = OutputFileStream(potentialPath);
               file.writeContent(outputStream);
               outputStream.close();
           }
        }
      }
    } catch (e) {
      print("Import failed: $e");
      rethrow;
    } finally {
      await scanTextures();
    }
  }
}
