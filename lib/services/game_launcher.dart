
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:hyta_launcher/services/config.dart';
import 'package:hyta_launcher/utils/butler.dart';
import 'package:hyta_launcher/utils/java_manager.dart';

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

class GameLauncher {
  final http.Client _client = http.Client();
  final http.Client _quickClient = http.Client(); 

  late String _launcherDir;
  late String _gameDir;
  late String _userDataDir;

  bool _isInitialized = false;

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
      final url = "${Config.patchBaseUrl}/$branch/0/$ver.pwr";
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

  Future<void> launchGame(
      String playerName, 
      GameVersion version, 
      Function(String) onStatus, 
      Function(double) onProgress) async {
    
    await init();
    final javaManager = JavaManager(_launcherDir, _gameDir);
    final javaExe = await javaManager.ensureJava(onStatus);

    onStatus("Checking game files...");
    await _downloadGame(version, onStatus, onProgress);

    onStatus("Launching...");
    final gameDir = p.join(_gameDir, version.branch, 'package', 'game', 'latest');
    final clientPath = p.join(gameDir, 'Client', 'HytaleClient'); 

    if (await File(clientPath).exists()) {
       await Process.run('chmod', ['+x', clientPath]);
    }

    final uuid = _getOrCreateUuid(playerName);

    final args = [
      '--app-dir', gameDir,
      '--user-dir', _userDataDir,
      '--java-exec', javaExe,
      '--auth-mode', 'offline',
      '--uuid', uuid,
      '--name', playerName
    ];
    
    Process.start(clientPath, args, 
        workingDirectory: p.dirname(clientPath),
        mode: ProcessStartMode.detached
    );
  }

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
    final pwrUrl = "${Config.patchBaseUrl}/${version.branch}/0/$pwrFile";
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
}
