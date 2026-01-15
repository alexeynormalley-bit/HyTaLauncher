
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
      final response = await http
          .get(Uri.parse("https://launcher.hytale.com/version/release/jre.json"));
      
      if (response.statusCode != 200) {
        throw Exception("Failed to get JRE info: ${response.statusCode}");
      }
      
      final Map<String, dynamic> data = jsonDecode(response.body);
      final downloadUrl = data['download_url'];



      final osData = downloadUrl['linux'];
      if (osData == null) {
         throw Exception("No Linux JRE available");
      }
      
      final archData = osData['amd64'];
      if (archData == null) {
        throw Exception("No 64-bit Linux JRE available");
      }
      
      final url = archData['url'];
      final fileName = p.basename(Uri.parse(url).path);
      final cacheDir = p.join(launcherDir, 'cache');
      final cachePath = p.join(cacheDir, fileName);
      
      await Directory(cacheDir).create(recursive: true);

      onStatus("Downloading JRE...");
      await _downloadFile(url, cachePath);

      onStatus("Extracting JRE...");
      await Directory(jreDir).create(recursive: true);


      if (fileName.endsWith('.tar.gz') || fileName.endsWith('.tgz')) {
         await Process.run('tar', ['-xzf', cachePath, '-C', jreDir]);
       } else if (fileName.endsWith('.zip')) {
        final bytes = await File(cachePath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        extractArchiveToDisk(archive, jreDir);
       } else {
         throw Exception("Unknown archive format: $fileName");
       }
       


       final entities = await Directory(jreDir).list().toList();
       if (entities.length == 1 && entities.first is Directory) {
         final subDir = entities.first as Directory;
         await Process.run('sh', ['-c', 'mv "${subDir.path}"/* "${jreDir}"/']);
         await subDir.delete(recursive: true);
       }
       
       await File(cachePath).delete();
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
    if (response.statusCode == 200) {
      await File(destPath).writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file');
    }
  }
}
