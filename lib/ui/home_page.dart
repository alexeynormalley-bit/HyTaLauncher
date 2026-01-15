import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/game_launcher.dart';

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
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("LOGIN", style: GoogleFonts.getFont('Doto', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _nicknameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: "NICKNAME",
                          floatingLabelStyle: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedBranch,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "BRANCH", floatingLabelStyle: TextStyle(color: Colors.red)),
                            dropdownColor: const Color(0xFF101010),
                            items: ["release", "beta", "alpha"].map((b) => DropdownMenuItem(
                                value: b, 
                                child: Text(b.toUpperCase(), 
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.getFont('Doto', color: Colors.white)
                                )
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
                        const SizedBox(width: 16),
                        Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    side: const BorderSide(color: Colors.white24),
                                    shape: const RoundedRectangleBorder(),
                                    padding: const EdgeInsets.symmetric(vertical: 22)
                                ),
                                onPressed: _showInstalledVersionsDialog,
                                child: Text(_selectedVersion?.name ?? "SELECT VERSION", 
                                    style: GoogleFonts.getFont('Doto', color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                ),
                            )
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Consumer<GameLauncher>(
                      builder: (context, launcher, _) {
                        return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: launcher.isGameRunning ? Colors.red.shade900 : const Color(0xFFFF0000),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                ),
                                onPressed: _isLoading 
                                    ? null 
                                    : (launcher.isGameRunning 
                                        ? () => launcher.killGame() 
                                        : _launch),
                                child: _isLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                    : Text(launcher.isGameRunning ? "FORCE CLOSE" : "PLAY", 
                                        style: GoogleFonts.getFont('Doto', fontSize: 18, fontWeight: FontWeight.bold))
                            ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),
          

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                if (_isLoading)
                  LinearProgressIndicator(value: _progress > 0 ? _progress / 100 : null, color: const Color(0xFFFF0000), backgroundColor: Colors.white24),
                const SizedBox(height: 8),
                Text(_status.toUpperCase(), style: GoogleFonts.getFont('Doto', color: Colors.white54, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _showInstalledVersionsDialog() async {
      final launcher = context.read<GameLauncher>();
      
      List<GameVersion> onlineVersions = [];
      try {
         onlineVersions = await launcher.getAvailableVersions(_selectedBranch, (s){}, (p){});
      } catch (e) {
      }

      final installedVersions = await launcher.scanInstalledVersions();
      
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              backgroundColor: Colors.black,
              shape:  Border.all(color: Colors.white),
              title: Text("SELECT VERSION", style: GoogleFonts.getFont('Doto', color: Colors.white)),
              content: SizedBox(
                  width: 300,
                  height: 400,
                  child: ListView(
                      children: [
                          if (onlineVersions.isNotEmpty) ...[
                             Text("Online (Auto-Update)", style: GoogleFonts.getFont('Doto', color: Colors.blueAccent, fontSize: 12)),
                             const Divider(color: Colors.white24),
                             ...onlineVersions.map((v) => ListTile(
                                 title: Text(v.name, style: GoogleFonts.inter(color: Colors.white)),
                                 onTap: () {
                                     setState(() {
                                         _selectedVersion = v;
                                         launcher.setVersionOverride(null); 
                                     });
                                     Navigator.pop(ctx);
                                 },
                             ))
                          ],
                          const SizedBox(height: 16),
                          if (installedVersions.isNotEmpty) ...[
                             Text("Installed (Offline)", style: GoogleFonts.getFont('Doto', color: Colors.greenAccent, fontSize: 12)),
                             const Divider(color: Colors.white24),
                              ...installedVersions.map((v) => ListTile(
                                 title: Text(v.name, style: GoogleFonts.inter(color: Colors.white)),
                                 subtitle: Text(v.branch, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                 onTap: () {
                                     setState(() {
                                         _selectedVersion = v;
                                         launcher.setVersionOverride(v); 
                                     });
                                     Navigator.pop(ctx);
                                 },
                             ))
                          ]
                      ],
                  ),
              ),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.red))
                  )
              ],
          )
      );
  }
}
