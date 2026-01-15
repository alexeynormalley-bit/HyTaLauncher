import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class ServerManager extends ChangeNotifier {
  final String _gameDir;
  final String _javaExe;
  
  Process? _serverProcess;
  final List<String> _logs = [];
  bool _isRunning = false;
  int? _serverPort;
  
  ServerManager({required String gameDir, required String javaExe})
      : _gameDir = gameDir,
        _javaExe = javaExe;
  
  bool get isRunning => _isRunning;
  List<String> get logs => List.unmodifiable(_logs);
  int? get serverPort => _serverPort;
  String get gameDir => _gameDir;
  
  String get _serverJarPath => p.join(_gameDir, 'Server', 'HytaleServer.jar');
  String get _assetsPath => p.join(_gameDir, 'Assets.zip');
  
  Future<bool> startServer({int port = 5520, String authMode = 'insecure'}) async {
    if (_isRunning) {
      _logs.add('[ServerManager] Server is already running');
      notifyListeners();
      return false;
    }
    
    final jarFile = File(_serverJarPath);
    if (!await jarFile.exists()) {
      _logs.add('[ServerManager] HytaleServer.jar not found at $_serverJarPath');
      notifyListeners();
      return false;
    }
    
    _logs.add('[ServerManager] Starting server on port $port...');
    notifyListeners();
    
    try {
      _serverProcess = await Process.start(
        _javaExe,
        [
          '-jar', _serverJarPath,
          '--assets', _assetsPath,
          '--auth-mode', authMode,
          '-b', '0.0.0.0:$port',
        ],
        workingDirectory: _gameDir,
      );
      
      _isRunning = true;
      _serverPort = port;
      _logs.add('[ServerManager] Server process started (PID: ${_serverProcess!.pid})');
      notifyListeners();
      
      _serverProcess!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            _logs.add(line);
            if (_logs.length > 1000) _logs.removeAt(0);
            notifyListeners();
          }
        }
      });
      
      _serverProcess!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            _logs.add('[ERR] $line');
            if (_logs.length > 1000) _logs.removeAt(0);
            notifyListeners();
          }
        }
      });
      
      _serverProcess!.exitCode.then((code) {
        _logs.add('[ServerManager] Server exited with code $code');
        _isRunning = false;
        _serverProcess = null;
        _serverPort = null;
        notifyListeners();
      });
      
      return true;
    } catch (e) {
      _logs.add('[ServerManager] Failed to start server: $e');
      _isRunning = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> stopServer() async {
    if (!_isRunning || _serverProcess == null) {
      _logs.add('[ServerManager] Server is not running');
      notifyListeners();
      return;
    }
    
    _logs.add('[ServerManager] Stopping server...');
    notifyListeners();
    
    _serverProcess!.kill(ProcessSignal.sigterm);
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (_isRunning) {
      _serverProcess!.kill(ProcessSignal.sigkill);
      _logs.add('[ServerManager] Server force-killed');
    }
    
    _isRunning = false;
    _serverProcess = null;
    _serverPort = null;
    notifyListeners();
  }
  
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
  
  Future<void> sendCommand(String command) async {
    if (!_isRunning || _serverProcess == null) {
      _logs.add('[ServerManager] Cannot send command: server not running');
      notifyListeners();
      return;
    }
    
    _serverProcess!.stdin.writeln(command);
    _logs.add('> $command');
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}
