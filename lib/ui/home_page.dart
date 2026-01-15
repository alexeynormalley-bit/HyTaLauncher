import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/game_launcher.dart';
import 'package:hyta_launcher/ui/game_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nicknameController.text = prefs.getString('nickname') ?? "";
      final savedBranch = prefs.getString('branch');
      if (savedBranch != null) _selectedBranch = savedBranch;
    });
    _nicknameController.addListener(_saveSettings);
    _loadVersions();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nicknameController.text);
    await prefs.setString('branch', _selectedBranch);
    if (_selectedVersion != null) {
        await prefs.setString('version_name', _selectedVersion!.name);
        await prefs.setString('version_branch', _selectedVersion!.branch);
        await prefs.setBool('version_local', _selectedVersion!.isLocal);
    }
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final launcher = context.read<GameLauncher>();
      final onlineVersions = await launcher.getAvailableVersions(
          _selectedBranch, 
          (s) => setState(() => _status = s),
          (p) => setState(() => _progress = p)
      );
      
      final installedVersions = await launcher.scanInstalledVersions();
      
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('version_name');
      final savedBranch = prefs.getString('version_branch');
      final savedLocal = prefs.getBool('version_local') ?? false;

      GameVersion? match;
      
      if (savedLocal) {
          match = installedVersions.cast<GameVersion?>().firstWhere(
              (v) => v!.name == savedName && v.branch == savedBranch,
              orElse: () => null
          );
      }
      
      if (match == null) {
         match = onlineVersions.cast<GameVersion?>().firstWhere(
             (v) => v!.name == savedName && v.branch == savedBranch,
             orElse: () => null
         );
      }
      
      setState(() {
        _versions = onlineVersions;
        
        if (match != null) {
            _selectedVersion = match;
            if (match!.isLocal) {
                 launcher.setVersionOverride(match);
            }
        } else if (_versions.isNotEmpty && _selectedVersion == null) {
           _selectedVersion = _versions.first;
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Login",
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Enter your credentials",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filledTonal(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      title: const Text("Game Tools"),
                                    ),
                                    body: const GameSettingsPage()
                                  )
                                ));
                              },
                              icon: Icon(PhosphorIcons.wrench()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        
                        TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: "Nickname",
                            hintText: "Enter your nickname",
                            prefixIcon: Icon(PhosphorIcons.user()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Branch",
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownMenu<String>(
                                    initialSelection: _selectedBranch,
                                    expandedInsets: EdgeInsets.zero,
                                    onSelected: _isLoading ? null : (v) {
                                      if (v != null) {
                                        setState(() => _selectedBranch = v);
                                        _saveSettings();
                                        _loadVersions();
                                      }
                                    },
                                    dropdownMenuEntries: ["release", "beta", "alpha"]
                                        .map((b) => DropdownMenuEntry(
                                          value: b,
                                          label: b.toUpperCase(),
                                        ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Version",
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.tonal(
                                      onPressed: _showInstalledVersionsDialog,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedVersion?.name ?? "Select Version",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(PhosphorIcons.caretUpDown(), size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),
                        
                        Consumer<GameLauncher>(
                          builder: (context, launcher, _) {
                            final isRunning = launcher.isGameRunning;
                            return SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: isRunning
                                ? FilledButton.tonal(
                                    onPressed: _isLoading ? null : () => launcher.killGame(),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.errorContainer,
                                      foregroundColor: colorScheme.onErrorContainer,
                                    ),
                                    child: _isLoading
                                      ? const SizedBox(
                                          width: 24, height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2.5),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(PhosphorIcons.stop()),
                                            const SizedBox(width: 8),
                                            const Text("Force Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                  )
                                : FilledButton(
                                    onPressed: _isLoading ? null : _launch,
                                    child: _isLoading
                                      ? const SizedBox(
                                          width: 24, height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(PhosphorIcons.play()),
                                            const SizedBox(width: 8),
                                            const Text("Play", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                  ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress / 100 : null,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _status.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showInstalledVersionsDialog() async {
      final launcher = context.read<GameLauncher>();
      final colorScheme = Theme.of(context).colorScheme;
      
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("SELECT VERSION", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
              content: SizedBox(
                  width: 300,
                  height: 400,
                  child: ListView(
                      children: [
                          if (onlineVersions.isNotEmpty) ...[
                             Text("Online (Auto-Update)", style: GoogleFonts.roboto(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                             Divider(color: colorScheme.outline),
                             ...onlineVersions.map((v) => ListTile(
                                 title: Text(v.name),
                                 onTap: () {
                                     setState(() {
                                         _selectedVersion = v;
                                         launcher.setVersionOverride(null); 
                                     });
                                     _saveSettings();
                                     Navigator.pop(ctx);
                                 },
                             ))
                          ],
                          const SizedBox(height: 16),
                          if (installedVersions.isNotEmpty) ...[
                             Text("Installed (Offline)", style: GoogleFonts.roboto(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold)),
                             Divider(color: colorScheme.outline),
                              ...installedVersions.map((v) => ListTile(
                                 title: Text(v.name),
                                 subtitle: Text(v.branch, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10)),
                                 onTap: () {
                                     setState(() {
                                         _selectedVersion = v;
                                         launcher.setVersionOverride(v); 
                                     });
                                     _saveSettings();
                                     Navigator.pop(ctx);
                                 },
                                 trailing: IconButton(
                                     icon: Icon(Icons.delete, color: colorScheme.error),
                                     onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogCtx) => AlertDialog(
                                                title: Text("DELETE VERSION?", style: GoogleFonts.roboto(color: colorScheme.error, fontWeight: FontWeight.bold)),
                                                content: Text("Are you sure you want to delete ${v.name}?"),
                                                actions: [
                                                    TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text("CANCEL")),
                                                    FilledButton(
                                                      style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                                      onPressed: () => Navigator.pop(dialogCtx, true), 
                                                      child: const Text("DELETE")
                                                    ),
                                                ]
                                            )
                                        );
                                        
                                        if (confirm == true) {
                                            Navigator.pop(ctx);
                                            final success = await launcher.deleteInstalledVersion(v);
                                            if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(success ? "Version deleted" : "Delete failed"))
                                                );
                                                _loadVersions();
                                            }
                                        }
                                     },
                                 ),
                             ))
                          ]
                      ],
                  ),
              ),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("CANCEL")
                  )
              ],
          )
      );
  }
}
