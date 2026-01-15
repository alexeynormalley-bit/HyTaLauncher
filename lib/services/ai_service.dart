import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models";
  
  static const String PREF_API_KEY = "ai_api_key";
  static const String PREF_MODEL = "ai_model";
  static const String PREF_HISTORY = "ai_history"; 

  String? _apiKey;
  String _model = "gemini-3-flash-preview"; 
  
  static const List<String> availableModels = [
      "gemini-3-flash-preview", 
      "gemini-3-pro-preview"
  ];

  Future<void> init() async {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(PREF_API_KEY);
      _model = prefs.getString(PREF_MODEL) ?? "gemini-3-flash-preview";
      
      if (!availableModels.contains(_model)) {
          _model = "gemini-3-flash-preview";
      }
  }

  Future<void> setApiKey(String key) async {
      _apiKey = key;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_API_KEY, key);
  }

  Future<void> setModel(String model) async {
      _model = model;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_MODEL, model);
  }

  String get currentModel => _model;
  String? get apiKey => _apiKey;

  Future<String> sendMessage(String message, List<String> logs) async {
      if (_apiKey == null || _apiKey!.isEmpty) {
          return "Please set your Gemini API Key in the AI settings.";
      }

      final contextBuffer = StringBuffer();
      contextBuffer.writeln("You are an intelligent AI assistant for the HyTaLauncher (Hytale Launcher).");
      contextBuffer.writeln("You are an intelligent AI assistant for the HyTaLauncher (Hytale Launcher).");
      contextBuffer.writeln("Your goal is to help the user manage their launcher configuration and debug issues.");
      
      contextBuffer.writeln("\n### Hytale Technical Knowledge Base (Latest Dataset)");
      contextBuffer.writeln("- **Architecture**: Server-side first. Mods are primarily server Plugins (Java .jar) or Data Assets (JSON).");
      contextBuffer.writeln("- **Assets**: Models/Textures use standard formats (JSON definitions). Clients download necessary assets on join.");
      contextBuffer.writeln("- **Scripting**: NPC behaviors and world gen are driven by JSON data assets and Java plugins.");
      
      contextBuffer.writeln("\n### Launcher Control Capabilities");
      contextBuffer.writeln("You can control the launcher settings directly. Use the strict output format below:");
      contextBuffer.writeln("- **RAM**: `[SET_RAM] <mb>` (e.g., `[SET_RAM] 8192`)");
      contextBuffer.writeln("- **Java Path**: `[SET_JAVA] <path>` (e.g., `[SET_JAVA] /usr/lib/jvm/java-21-openjdk`)");
      contextBuffer.writeln("- **Launch Flags**: `[SET_FLAGS] <flags>` (e.g., `[SET_FLAGS] --fullscreen --no-audio`)");
      
      contextBuffer.writeln(" *If the user asks to change settings or optimized configuration based on logs, output the corresponding command(s).*");
      
      contextBuffer.writeln("\n### Diagnostics");
      contextBuffer.writeln("Analyze the logs below for crashes, errors, or status updates. Explain issues clearly.");
      
      contextBuffer.writeln("\n--- RECENT LOGS ---");
      final recentLogs = logs.length > 100 ? logs.sublist(logs.length - 100) : logs;
      for (var log in recentLogs) {
          contextBuffer.writeln(log);
      }
      contextBuffer.writeln("--- END LOGS ---");
      
      contextBuffer.writeln("\nUser Query: $message");

      final url = "$_baseUrl/$_model:generateContent?key=$_apiKey";
      
      try {
          final response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                  "contents": [{
                      "parts": [{"text": contextBuffer.toString()}]
                  }]
              })
          );

          if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
              return text ?? "No response from AI.";
          } else {
              try {
                  final err = jsonDecode(response.body);
                  return "API Error: ${err['error']['message']}";
              } catch (_) {
                  return "Error: ${response.statusCode} - ${response.body}";
              }
          }
      } catch (e) {
          return "Network Error: $e";
      }
  }
}
