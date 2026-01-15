import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
class JavaManager {
  final String launcherDir;
  final String gameDir;
  JavaManager(this.launcherDir, this.gameDir);
  Future<String> ensureJava(Function(String) onStatus) async {
    final jreDir = p.join(gameDir, 'release', 'package', 'jre', 'latest');
    final javaExe = p.join(jreDir, 'bin', 'java');
    if (await File(javaExe).exists()) {
      return javaExe;
    }
    onStatus("Checking JRE...");
    try {
      final url = "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk";
      final fileName = "jdk21.tar.gz";
      final cacheDir = p.join(launcherDir, 'cache');
      final cachePath = p.join(cacheDir, fileName);
      await Directory(cacheDir).create(recursive: true);
      onStatus("Downloading JRE directly...");
      await _downloadFile(url, cachePath);
      onStatus("Extracting JRE...");
      await Directory(jreDir).create(recursive: true);
      if (await Directory(jreDir).exists()) await Directory(jreDir).delete(recursive: true);
      await Directory(jreDir).create(recursive: true);
      await Process.run('tar', ['-xzf', cachePath, '-C', jreDir]);
       final entities = await Directory(jreDir).list().toList();
       if (entities.length == 1 && entities.first is Directory) {
         final subDir = entities.first as Directory;
         await Process.run('sh', ['-c', 'mv "${subDir.path}"/* "${jreDir}"/']);
         await subDir.delete(recursive: true);
       }
       if (await File(cachePath).exists()) await File(cachePath).delete();
       await Process.run('chmod', ['+x', javaExe]);
       return javaExe;
    } catch (e) {
      print("Error downloading JRE: $e");
      onStatus("Using system Java...");
      return "java"; 
    }
  }
  Future<void> _downloadFile(String url, String destPath) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200 || response.statusCode == 302) {
      await File(destPath).writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file');
    }
  }
}
