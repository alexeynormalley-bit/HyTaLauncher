import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:hyta_launcher/services/config.dart';
import 'package:hyta_launcher/utils/butler.dart';
import 'package:hyta_launcher/utils/java_manager.dart';
import 'package:flutter/services.dart';
class GameVersion {
  final String name;
  final String pwrFile;
  final String branch;
  final int prevVersion;
  final int version;
  final bool isLatest;
  GameVersion({
    required this.name,
    required this.pwrFile,
    this.branch = "release",
    this.prevVersion = 0,
    required this.version,
    this.isLatest = false,
  });
}
class GameLauncher extends ChangeNotifier {
  final http.Client _client = http.Client();
  final http.Client _quickClient = http.Client(); 
  late String _launcherDir;
  late String _gameDir;
  late String _userDataDir;
  bool _isInitialized = false;
  Process? _process;
  bool get isGameRunning => _process != null;
  String get gameDir => _isInitialized ? p.join(_gameDir, 'release', 'package', 'game', 'latest') : '';
  String get javaExe => _isInitialized ? p.join(_gameDir, 'release', 'package', 'jre', 'latest', 'bin', 'java') : '';
  Future<void> init() async {
    if (_isInitialized) return;
    final home = Platform.environment['HOME'] ?? '/';
    final shareDir = p.join(home, '.local', 'share');
    _launcherDir = p.join(shareDir, 'HyTaLauncher');
    _gameDir = p.join(shareDir, 'Hytale', 'install');
    _userDataDir = p.join(_launcherDir, 'UserData');
    await Directory(_launcherDir).create(recursive: true);
    await Directory(_gameDir).create(recursive: true);
    await Directory(_userDataDir).create(recursive: true);
    await Directory(p.join(_launcherDir, 'cache')).create(recursive: true);
    _isInitialized = true;
  }
  Future<void> killGame() async {
      if (_process != null) {
          _process!.kill(ProcessSignal.sigkill);
          _process = null;
          notifyListeners();
      }
  }
  void injectCommand(String command) {
      if (_process != null) {
          _process!.stdin.writeln(command);
          _logs.add("[LAUNCHER] Injected: $command");
          notifyListeners();
      } else {
          _logs.add("[LAUNCHER] Cannot inject: Game not running.");
          notifyListeners();
      }
  }
  void clearLogs() {
      _logs.clear();
      notifyListeners();
  }
  Future<List<GameVersion>> getAvailableVersions(
      String branch, Function(String) onStatus, Function(double) onProgress) async {
    await init();
    onStatus("Checking versions...");
    List<GameVersion> versions = [];
    int maxVersion = 0;
    int consecutiveMisses = 0;
    int ver = 1;
    const consecutiveMissesToStop = 5;
    while (consecutiveMisses < consecutiveMissesToStop) {
      final url = "${Config.patchBaseUrl}/linux/amd64/$branch/0/$ver.pwr";
      try {
        final response = await _quickClient.head(Uri.parse(url));
        if (response.statusCode == 200) {
          maxVersion = ver;
          consecutiveMisses = 0;
        } else {
          consecutiveMisses++;
        }
      } catch (e) {
        consecutiveMisses++;
      }
      ver++;
    }
    if (maxVersion > 0) {
        versions.add(GameVersion(
            name: "Latest (v$maxVersion)",
            pwrFile: "$maxVersion.pwr",
            branch: branch,
            version: maxVersion,
            isLatest: true
        ));
    } else {
        versions.add(GameVersion(name: "Latest", pwrFile: "1.pwr", version: 1, isLatest: true));
    }
    return versions;
  }
  GameVersion? _versionOverride;
  void setVersionOverride(GameVersion? version) {
      _versionOverride = version;
      notifyListeners();
  }
  Future<List<GameVersion>> scanInstalledVersions() async {
      await init();
      List<GameVersion> installed = [];
      final Directory root = Directory(_gameDir);
      if (!await root.exists()) return [];
      await for (final branchEntity in root.list()) {
          if (branchEntity is Directory) {
             final branchName = p.basename(branchEntity.path);
             final packageGame = Directory(p.join(branchEntity.path, 'package', 'game'));
             if (await packageGame.exists()) {
                 await for (final verEntity in packageGame.list()) {
                     if (verEntity is Directory) {
                         final verName = p.basename(verEntity.path);
                         installed.add(GameVersion(
                             name: "Installed: $branchName/$verName",
                             pwrFile: "", 
                             branch: branchName,
                             version: 0, 
                             isLatest: verName == 'latest'
                         ));
                     }
                 }
             }
          }
      }
      return installed;
  }
  Future<void> launchGame(
      String playerName, 
      GameVersion version, 
      Function(String) onStatus, 
      Function(double) onProgress) async {
    await init();
    final javaManager = JavaManager(_launcherDir, _gameDir);
    final javaExe = await javaManager.ensureJava(onStatus);
    onStatus("Checking game files...");
    String targetGameDir;
    if (_versionOverride != null) {
        onStatus("Using selected version: ${_versionOverride!.name}");
        final vName = _versionOverride!.name.split('/').last; 
        if (version.pwrFile.isEmpty) {
             onStatus("Skipping update check for installed version.");
        } else {
             await _downloadGame(version, onStatus, onProgress);
        }
        final folderName = version.name.contains('/') ? version.name.split('/').last : 'latest'; 
        String specificBuild = 'latest';
        if (version.name.startsWith("Installed:")) {
             specificBuild = version.name.split('/').last;
        }
        targetGameDir = p.join(_gameDir, version.branch, 'package', 'game', specificBuild);
    } else {
        await _downloadGame(version, onStatus, onProgress);
        targetGameDir = p.join(_gameDir, version.branch, 'package', 'game', 'latest');
    }
    onStatus("Launching from $targetGameDir...");
    final clientPath = p.join(targetGameDir, 'Client', 'HytaleClient'); 
    final gameDir = targetGameDir; 
    if (await File(clientPath).exists()) {
       await Process.run('chmod', ['+x', clientPath]);
    }
    final uuid = _getOrCreateUuid(playerName);
    final prefs = await SharedPreferences.getInstance();
    final customFlags = prefs.getString('custom_flags') ?? "";
    final flagArgs = customFlags.isNotEmpty ? customFlags.split(' ') : [];
    final lang = prefs.getString('language_code') ?? 'en';
    final exeDir = p.dirname(Platform.resolvedExecutable);
    var russifierSourceLine = p.join(exeDir, 'data', 'flutter_assets', 'assets', 'russifier');
    if (!await Directory(russifierSourceLine).exists()) {
        final projectRoot = p.dirname(p.dirname(p.dirname(p.dirname(exeDir)))); 
        final devPath = p.join(projectRoot, 'assets', 'russifier');
    }
    if (lang == 'ru') {
        onStatus("Checking Russifier at: $russifierSourceLine");
        if (await Directory(russifierSourceLine).exists()) {
             onStatus("Found Russifier assets. Applying...");
             try {
                await _applyRussifier(russifierSourceLine, gameDir);
                onStatus("Russifier applied successfully.");
             } catch (e) {
                onStatus("Error applying Russifier: $e");
             }
        } else {
             onStatus("Russifier NOT found at $russifierSourceLine.");
        }
    } else {
        await _revertRussifier(gameDir);
    }
    final List<String> args = [
      '--app-dir', gameDir,
      '--user-dir', _userDataDir,
      '--java-exec', javaExe,
      '--auth-mode', 'insecure',
      '--identity-token', _generateDummyJwt(uuid, playerName),
      '--session-token', _generateDummyJwt(uuid, playerName),
      '--uuid', uuid,
      '--name', playerName,
      ...flagArgs
    ];
    _logs.clear();
    _logs.add("Launching with args: $args");
    notifyListeners();
    _process = await Process.start(clientPath, args, 
        workingDirectory: p.dirname(clientPath),
    );
    notifyListeners();
    _process!.stdout.transform(utf8.decoder).listen((data) {
        _logs.add(data.trim());
        notifyListeners();
    });
    _process!.stderr.transform(utf8.decoder).listen((data) {
        _logs.add("[ERR] ${data.trim()}");
        notifyListeners();
    });
    _process!.exitCode.then((code) {
        _logs.add("Process exited with code $code");
        _process = null;
        notifyListeners();
    });
  }
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);
  Future<void> _downloadGame(
      GameVersion version, Function(String) onStatus, Function(double) onProgress) async {
    final gameDir = p.join(_gameDir, version.branch, 'package', 'game', 'latest');
    final versionFile = p.join(gameDir, '.version');
    int installedVersion = 0;
    if (await File(versionFile).exists()) {
      installedVersion = int.tryParse((await File(versionFile).readAsString()).trim()) ?? 0;
    }
    if (installedVersion == version.version) {
        onStatus("Ready to launch!");
        onProgress(100);
        return;
    }
    onStatus("Downloading game content...");
    final pwrFile = "${version.version}.pwr";
    final pwrUrl = "${Config.patchBaseUrl}/linux/amd64/${version.branch}/0/$pwrFile";
    final pwrPath = p.join(_launcherDir, 'cache', "linux_${version.branch}_0_$pwrFile");
    onStatus("Downloading patch $pwrFile...");
    await _downloadFile(pwrUrl, pwrPath, onProgress);
    onStatus("Installing...");
    final butler = Butler(_launcherDir);
    await butler.applyPwr(pwrPath, gameDir, onStatus);
    await File(versionFile).writeAsString(version.version.toString());
  }
  Future<void> _downloadFile(String url, String destPath, Function(double) onProgress) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request);
    if (response.statusCode != 200) throw Exception("Download failed: ${response.statusCode}");
    final contentLength = response.contentLength ?? 0;
    var downloaded = 0;
    final file = File(destPath);
    final sink = file.openWrite();
    await response.stream.listen((chunk) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
            onProgress(downloaded / contentLength * 100);
        }
    }).asFuture();
    await sink.close();
  }
  String _getOrCreateUuid(String playerName) {
    final uuid = Uuid();
    return uuid.v5(Uuid.NAMESPACE_URL, "OfflinePlayer:$playerName");
  }
  Future<void> _applyRussifier(String sourceDir, String gameDir) async {
      Future<void> copyRecursive(Directory source, Directory target) async {
          if (!await target.exists()) await target.create(recursive: true);
          await for (final entity in source.list(recursive: false)) {
              if (entity is Directory) {
                  await copyRecursive(entity, Directory(p.join(target.path, p.basename(entity.path))));
              } else if (entity is File) {
                  final targetFile = File(p.join(target.path, p.basename(entity.path)));
                  final backupFile = File("${targetFile.path}.bak");
                  if (await targetFile.exists() && !await backupFile.exists()) {
                      await targetFile.copy(backupFile.path);
                  }
                  await entity.copy(targetFile.path);
              }
          }
      }
      await copyRecursive(Directory(p.join(sourceDir, 'Client')), Directory(p.join(gameDir, 'Client')));
      if (await Directory(p.join(sourceDir, 'Assets')).exists()) {
          await copyRecursive(Directory(p.join(sourceDir, 'Assets')), Directory(p.join(gameDir, 'Assets')));
      }
  }
  Future<void> _revertRussifier(String gameDir) async {
      Future<void> restoreRecursive(Directory dir) async {
          if (!await dir.exists()) return;
          await for (final entity in dir.list(recursive: false)) {
              if (entity is Directory) {
                  await restoreRecursive(entity);
              } else if (entity is File && entity.path.endsWith('.bak')) {
                  final originalPath = entity.path.substring(0, entity.path.length - 4);
                  await entity.copy(originalPath);
                  await entity.delete();
              }
          }
      }
      await restoreRecursive(Directory(p.join(gameDir, 'Client')));
      await restoreRecursive(Directory(p.join(gameDir, 'Assets')));
  }
  String get _fixSourcePath => p.join(_launcherDir, 'fix_source');

  Future<void> _extractFixAssets() async {
    final fixDir = Directory(_fixSourcePath);
    if (!await fixDir.exists()) {
       await fixDir.create(recursive: true);
    }
    
    final assets = [
      'assets/fix/Server/start-server.bat',
    ];

    for (final assetPath in assets) {
      try {
        final relativePath = assetPath.replaceFirst('assets/fix/', '');
        final targetPath = p.join(_fixSourcePath, relativePath);
        final targetFile = File(targetPath);
        
        if (!await targetFile.exists()) {
           await Directory(p.dirname(targetPath)).create(recursive: true);
           final data = await rootBundle.load(assetPath);
           final bytes = data.buffer.asUint8List();
           await targetFile.writeAsBytes(bytes);
        }
      } catch (e) {
        print("Error extracting $assetPath: $e");
      }
    }
  }

  Future<bool> isOnlineFixAvailable() async {
    await _extractFixAssets();
    // Check if the critical JAR exists (it's not bundled, so must be placed manually or by git clone)
    if (!await File(p.join(_fixSourcePath, 'Server', 'HytaleServer.jar')).exists()) {
        return false;
    }
    return await Directory(_fixSourcePath).exists();
  }

  Future<void> applyOnlineFix() async {
    _logs.add("applying online fix...");
    notifyListeners();
    
    await _extractFixAssets();
    
    if (!await File(p.join(_fixSourcePath, 'Server', 'HytaleServer.jar')).exists()) {
      _logs.add("[ERROR] HytaleServer.jar not found!");
      _logs.add("Please download HytaleServer.jar from GitHub Releases");
      _logs.add("and place it in: ${_fixSourcePath}/Server/");
      notifyListeners();
      return;
    }

    if (!await isOnlineFixAvailable()) {
      _logs.add("online fix source not found at $_fixSourcePath");
      notifyListeners();
      return;
    }
    try {
      String gameDir;
      if (_versionOverride != null) {
          String specificBuild = 'latest';
          if (_versionOverride!.name.startsWith("Installed:")) {
               specificBuild = _versionOverride!.name.split('/').last;
          }
          gameDir = p.join(_gameDir, _versionOverride!.branch, 'package', 'game', specificBuild);
          _logs.add("applying fix to selected version: ${_versionOverride!.name}");
      } else {
          gameDir = p.join(_gameDir, 'sbox_core', 'package', 'game', 'latest');
          _logs.add("applying fix to default latest version...");
      }
      if (!await Directory(gameDir).exists()) {
         _logs.add("game directory not found at $gameDir. launch game once to download.");
         notifyListeners();
         return;
      }
      final serverSource = p.join(_fixSourcePath, 'Server', 'HytaleServer.jar');
      final serverTarget = p.join(gameDir, 'Server', 'HytaleServer.jar');
      if (await File(serverSource).exists()) {
        _logs.add("patching hytaleserver.jar...");
        notifyListeners();
        final backupTarget = "$serverTarget.bak";
        if (!await File(backupTarget).exists() && await File(serverTarget).exists()) {
           await File(serverTarget).copy(backupTarget);
        }
        await File(serverSource).copy(serverTarget);
      } else {
        _logs.add("warning: hytaleserver.jar not found in fix source.");
        notifyListeners();
      }
      final clientSource = p.join(_fixSourcePath, 'Client');
      final clientTarget = p.join(gameDir, 'Client');
      final windowsExe = File(p.join(clientTarget, 'HytaleClient.exe'));
      if (await windowsExe.exists()) {
          await windowsExe.delete();
          _logs.add("removed useless HytaleClient.exe");
          notifyListeners();
      }
      _logs.add("online fix applied successfully!");
      notifyListeners();
    } catch (e) {
      _logs.add("error applying online fix: $e");
      notifyListeners();
    }
  }
  String _generateDummyJwt(String uuid, String name) {
      String base64Url(String input) {
          return base64UrlEncode(utf8.encode(input)).replaceAll('=', '');
      }
      final header = base64Url('{"alg":"HS256","typ":"JWT"}');
      final iat = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final exp = iat + 86400;
      final payload = base64Url('{"sub":"$uuid","name":"$name","scope":"hytale:client","iat":$iat,"exp":$exp}');
      final signature = base64Url('fake_signature_for_insecure_mode');
      return "$header.$payload.$signature";
  }

  Future<bool> deleteInstalledVersion() async {
    await init();
    try {
      final releaseDir = p.join(_gameDir, 'release');
      final dir = Directory(releaseDir);
      
      if (await dir.exists()) {
        _logs.add('[Launcher] Deleting installed game version...');
        notifyListeners();
        
        await dir.delete(recursive: true);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('installed_version');
        
        _logs.add('[Launcher] Game files deleted. Ready to re-download.');
        notifyListeners();
        return true;
      } else {
        _logs.add('[Launcher] No installed version found.');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _logs.add('[Launcher] Delete failed: $e');
      notifyListeners();
      return false;
    }
  }
}
