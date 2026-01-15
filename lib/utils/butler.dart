
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
      // Ensure executable permission
      await Process.run('chmod', ['+x', butlerExe]);
      return butlerExe;
    }

    await Directory(butlerDir).create(recursive: true);

    print('Downloading Butler...');
    // Linux 64-bit URL
    const butlerUrl =
        "https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default";
    final zipPath = p.join(launcherDir, 'cache', 'butler.zip');
    await Directory(p.join(launcherDir, 'cache')).create(recursive: true);

    await _downloadFile(butlerUrl, zipPath);

    print('Extracting Butler...');
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    extractArchiveToDisk(archive, butlerDir);
    
    await File(zipPath).delete();

    await Process.run('chmod', ['+x', butlerExe]);
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

    // butler apply --staging-dir <dir> <patch> <target>
    final args = [
      'apply',
      '--staging-dir',
      stagingDir,
      pwrPath,
      gameDir
    ];

    print('Running: $butlerExe ${args.join(" ")}');

    // Ensure executable bit is set right before running
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
