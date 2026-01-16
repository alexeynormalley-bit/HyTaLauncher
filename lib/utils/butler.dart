import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';

class Butler {
  final String launcherDir;

  Butler(this.launcherDir);

  Future<String> ensureButler() async {
    final butlerDir = p.join(launcherDir, 'butler');
    final butlerExe = p.join(butlerDir, 'butler');

    if (await File(butlerExe).exists()) {
      await Process.run('chmod', ['+x', butlerExe]);
      return butlerExe;
    }

    await Directory(butlerDir).create(recursive: true);

    print('Downloading Butler from broth.itch.zone...');

    const butlerUrl = "https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default";
    final zipPath = p.join(launcherDir, 'cache', 'butler.zip');
    await Directory(p.join(launcherDir, 'cache')).create(recursive: true);

    int maxRetries = 3;
    Exception? lastError;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Download attempt $attempt/$maxRetries...');
        await _downloadFile(butlerUrl, zipPath);
        
        final file = File(zipPath);
        if (!await file.exists()) {
          throw Exception('Download failed: file not created');
        }
        final size = await file.length();
        if (size < 1000000) {
          throw Exception('Download incomplete: file too small ($size bytes)');
        }
        
        print('Download successful ($size bytes)');
        break;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('Download attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    
    if (!await File(zipPath).exists()) {
      throw Exception('Failed to download Butler after $maxRetries attempts: $lastError');
    }

    print('Extracting Butler...');
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    extractArchiveToDisk(archive, butlerDir);
    
    await File(zipPath).delete();

    if (!await File(butlerExe).exists()) {
      throw Exception('Butler extraction failed: executable not found at $butlerExe');
    }

    await Process.run('chmod', ['+x', butlerExe]);
    
    final lib7z = p.join(butlerDir, '7z.so');
    final libc7zip = p.join(butlerDir, 'libc7zip.so');
    if (await File(lib7z).exists()) {
      await Process.run('chmod', ['+x', lib7z]);
    }
    if (await File(libc7zip).exists()) {
      await Process.run('chmod', ['+x', libc7zip]);
    }
    
    print('Butler ready at $butlerExe');
    return butlerExe;
  }

  Future<void> applyPwr(
      String pwrPath, String gameDir, Function(String) onStatus) async {
    final butlerExe = await ensureButler();

    final stagingDir = p.join(gameDir, 'staging-temp');
    if (await Directory(stagingDir).exists()) {
      await Directory(stagingDir).delete(recursive: true);
    }
    await Directory(stagingDir).create(recursive: true);
    await Directory(gameDir).create(recursive: true);

    onStatus("Applying patch...");

    final args = [
      'apply',
      '--staging-dir',
      stagingDir,
      pwrPath,
      gameDir
    ];

    print('Running: $butlerExe ${args.join(" ")}');

    await Process.run('chmod', ['+x', butlerExe]);

    final process = await Process.start(butlerExe, args,
        workingDirectory: launcherDir);

    process.stdout.transform(utf8.decoder).listen((data) => print(data));
    process.stderr.transform(utf8.decoder).listen((data) => print(data));

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception('Butler failed with exit code $exitCode');
    }

    if (await Directory(stagingDir).exists()) {
      await Directory(stagingDir).delete(recursive: true);
    }
  }

  Future<void> _downloadFile(String url, String destPath) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await File(destPath).writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }
}
