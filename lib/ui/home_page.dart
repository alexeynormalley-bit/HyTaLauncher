
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hyta_launcher/services/game_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Need to add this dep

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nicknameController = TextEditingController();
  String _selectedBranch = "release";
  GameVersion? _selectedVersion;
  List<GameVersion> _versions = [];
  
  bool _isLoading = false;
  String _status = "Ready";
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final launcher = context.read<GameLauncher>();
      final versions = await launcher.getAvailableVersions(
          _selectedBranch, 
          (s) => setState(() => _status = s),
          (p) => setState(() => _progress = p)
      );
      
      setState(() {
        _versions = versions;
        if (versions.isNotEmpty) {
           _selectedVersion = versions.first;
        }
      });
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launch() async {
    if (_nicknameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a nickname"))
        );
        return;
    }
    if (_selectedVersion == null) return;
    
    setState(() {
        _isLoading = true;
        _progress = 0;
    });
    
    try {
        final launcher = context.read<GameLauncher>();
        await launcher.launchGame(
            _nicknameController.text,
            _selectedVersion!,
            (s) => setState(() => _status = s),
            (p) => setState(() => _progress = p)
        );
    } catch (e) {
        setState(() => _status = "Error: $e");
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
    } finally {
        setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("LOGIN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(labelText: "NICKNAME"),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedBranch,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "BRANCH"),
                            dropdownColor: Colors.black,
                            items: ["release", "beta", "alpha"].map((b) => DropdownMenuItem(
                                value: b, 
                                child: Text(b.toUpperCase(), overflow: TextOverflow.ellipsis)
                            )).toList(),
                            onChanged: _isLoading ? null : (v) {
                                if (v != null) {
                                    setState(() => _selectedBranch = v);
                                    _loadVersions();
                                }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<GameVersion>(
                            value: _selectedVersion,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "VERSION"),
                             dropdownColor: Colors.black,
                            items: _versions.map((v) => DropdownMenuItem(
                                value: v, 
                                child: Text(v.name, overflow: TextOverflow.ellipsis)
                            )).toList(),
                            onChanged: _isLoading ? null : (v) => setState(() => _selectedVersion = v),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _launch,
                            child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) 
                                : const Text("PLAY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Status Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                if (_isLoading)
                  LinearProgressIndicator(value: _progress > 0 ? _progress / 100 : null, color: Colors.white, backgroundColor: Colors.white24),
                const SizedBox(height: 8),
                Text(_status.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
