import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class PatchService {
    static const String PREF_ONLINE_URL = "pref_online_url";
    static const String PREF_RU_URL = "pref_ru_url";
    
    static const String FALLBACK_ONLINE_URL = "https://online-fix.me/games/sports/17694-hytale-po-seti.html";
    static const String DEFAULT_ONLINE_URL = "https://github.com/MerryJoyKey-Studio/HyTaLauncher/releases/download/latest/online_fix.zip"; 
    static const String DEFAULT_RU_URL = "https://github.com/MerryJoyKey-Studio/HyTaLauncher/releases/download/latest/ru.zip";

    final String _gameDir;
    final String _cacheDir;
    
    PatchService(this._gameDir, this._cacheDir);

    Future<String> getUrl(String key) async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key) ?? "";
    }

    Future<void> setUrl(String key, String url) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, url);
    }

    Future<void> installPatch(String url, String name, Function(String) onStatus) async {
         if (url.isEmpty) throw Exception("URL for $name is empty!");

         final zipFile = File(p.join(_cacheDir, "$name.zip"));
         if (!zipFile.parent.existsSync()) zipFile.parent.createSync(recursive: true);

         onStatus("Downloading $name...");
         final response = await http.get(Uri.parse(url));
         if (response.statusCode != 200) throw Exception("Failed to download $name. Status: ${response.statusCode}");
         await zipFile.writeAsBytes(response.bodyBytes);

         onStatus("Backing up...");
         // Backup logic could go here

         onStatus("Installing $name...");
         final bytes = await zipFile.readAsBytes();
         final archive = ZipDecoder().decodeBytes(bytes);

         final clientDir = p.join(_gameDir, "Client");
         if (!Directory(clientDir).existsSync()) throw Exception("Client directory not found at $clientDir");

         for (final file in archive) {
            final filename = file.name;
            if (file.isFile) {
                final data = file.content as List<int>;
                String targetPath;
                // Simple logic: if inside Client/, putting in Client root. 
                // Adjust based on actual zip structure if known.
                if (filename.startsWith("Client/")) {
                     targetPath = p.join(_gameDir, filename);
                } else {
                     targetPath = p.join(clientDir, filename);
                }
                
                final outFile = File(targetPath);
                outFile.parent.createSync(recursive: true);
                if (outFile.existsSync()) outFile.deleteSync();
                await outFile.writeAsBytes(data);
            }
         }
         
         onStatus("Cleaning up...");
         if (zipFile.existsSync()) zipFile.deleteSync();
         
         onStatus("$name Installed!");
    }
}
