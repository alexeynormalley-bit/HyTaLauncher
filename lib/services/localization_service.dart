import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Map<String, String> _localizedStrings = {};
  String _currentLang = 'en';
  
  String get currentLang => _currentLang;
  

  final Map<String, String> _enDefaults = {
    "app.title": "HyTaLauncher",
    "main.settings": "⚙ Settings",
    "main.play": "PLAY",
    "main.news": "HYTALE NEWS",
    "main.version": "VERSION",
    "settings.title": "⚙ Settings",
    "settings.game_folder": "GAME FOLDER",
    "settings.russifier": "RUSSIFIER",
    "settings.install_russifier": "Install Russifier",
    "settings.onlinefix": "ONLINE FIX",
    "settings.install_onlinefix": "Install Online Fix",
    "settings.save": "SAVE SETTINGS",
    "settings.cancel": "Cancel",
    "settings.interface_fps": "INTERFACE FRAME RATE (HZ)",
    "settings.max_ram": "MAX RAM (MB)",
    "tools.title": "RuLang",
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString('language') ?? 'en';
    await loadLanguage(_currentLang);
  }

  Future<void> loadLanguage(String langCode) async {
    _currentLang = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);

    if (langCode == 'en') {
      _localizedStrings = Map.from(_enDefaults);
      return;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/lang/$langCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print("Error loading language $langCode: $e");
      _localizedStrings = Map.from(_enDefaults);
    }
    
    notifyListeners();
  }

  String get(String key) {
    return _localizedStrings[key] ?? _enDefaults[key] ?? key;
  }
}
