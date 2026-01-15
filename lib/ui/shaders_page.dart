import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/shader_service.dart';
import 'package:path/path.dart' as p;

class ShadersPage extends StatefulWidget {
  const ShadersPage({super.key});

  @override
  State<ShadersPage> createState() => _ShadersPageState();
}

class _ShadersPageState extends State<ShadersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ShaderService _service;
  

  List<File> _textures = [];
  bool _isLoadingTextures = true;
  

  Map<String, dynamic> _renderSettings = {};
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }
  
  Future<void> _init() async {
    final home = Platform.environment['HOME'] ?? '/';
    final shareDir = p.join(home, '.local', 'share');
    final gamePath = p.join(shareDir, 'Hytale', 'install', 'release', 'package', 'game', 'latest');
    final userDataDir = p.join(shareDir, 'HyTaLauncher', 'UserData');
    
    _service = ShaderService(gamePath, userDataDir);
    _loadTextures();
    _loadConfig();
  }

  Future<void> _loadTextures() async {
    setState(() => _isLoadingTextures = true);
    final list = await _service.getShaderTextures();
    setState(() {
      _textures = list;
      _isLoadingTextures = false;
    });
  }
  
  Future<void> _loadConfig() async {
      setState(() => _isLoadingConfig = true);
      final settings = await _service.getRenderingSettings();
      setState(() {
          _renderSettings = settings;
          _isLoadingConfig = false;
      });
  }
  
  Future<void> _saveConfig() async {
      await _service.saveRenderingSettings(_renderSettings);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Render Config Saved! Restart Game to Apply.")));
  }

  Future<void> _replace(File target) async {
      const typeGroup = fs.XTypeGroup(label: 'Images', extensions: <String>['png', 'jpg']);
      final file = await fs.openFile(acceptedTypeGroups: <fs.XTypeGroup>[typeGroup]);
      if (file == null) return;
      await _service.replaceTexture(p.basename(target.path), file.path);
      await _loadTextures();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Texture Updated!")));
  }
  
  Future<void> _reset(File target) async {
      await _service.resetTexture(p.basename(target.path));
      await _loadTextures();
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Texture Reset!")));
  }
  
  Future<void> _importPreset() async {
      const typeGroup = fs.XTypeGroup(label: 'JSON Shader Preset', extensions: <String>['json']);
      final file = await fs.openFile(acceptedTypeGroups: <fs.XTypeGroup>[typeGroup]);
      if (file == null) return;
      await _service.importPreset(file.path);
      await _loadConfig();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preset Loaded!")));
  }
  
  Future<void> _exportPreset() async {
      final home = Platform.environment['HOME'] ?? '/';
      final presetDir = Directory(p.join(home, 'Documents', 'HyTaLauncher', 'Presets'));
      if (!presetDir.existsSync()) presetDir.createSync(recursive: true);
      
      final path = p.join(presetDir.path, "shader_config_${DateTime.now().millisecondsSinceEpoch}.json");
      await _service.exportPreset(path, "My Custom Shader", _renderSettings);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Preset Exported to $path")));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
            TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF0000),
                labelColor: const Color(0xFFFF0000),
                unselectedLabelColor: Colors.white54,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold),
                tabs: const [Tab(text: "ASSETS"), Tab(text: "CONFIGURATION")]
            ),
            Expanded(
                child: TabBarView(
                    controller: _tabController,
                    children: [
                        _buildAssetsTab(),
                        _buildConfigTab(),
                    ]
                )
            )
        ]
    );
  }
  
  Widget _buildAssetsTab() {
      if (_isLoadingTextures) return const Center(child: CircularProgressIndicator(color: Colors.white));
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
        itemCount: _textures.length,
        itemBuilder: (context, index) {
            final file = _textures[index];
            final name = p.basename(file.path);
            final isModified = _service.hasBackup(name);
            return Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    border: Border.all(color: isModified ? const Color(0xFFFF0000) : Colors.white10),
                ),
                child: Column(children: [
                    Expanded(child: Padding(padding: const EdgeInsets.all(12.0), child: Image.file(file, fit: BoxFit.contain))),
                    Text(name, style: GoogleFonts.getFont('Doto', color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        IconButton(icon: const Icon(Icons.upload_file, color: Colors.white70, size: 20), onPressed: () => _replace(file)),
                        if (isModified) IconButton(icon: const Icon(Icons.undo, color: Color(0xFFFF0000), size: 20), onPressed: () => _reset(file))
                    ]),
                    const SizedBox(height: 8),
                ])
            );
        }
    );
  }
  
  Widget _buildConfigTab() {
      if (_isLoadingConfig) return const Center(child: CircularProgressIndicator(color: Colors.white));
      
      return ListView(
          padding: const EdgeInsets.all(32),
          children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("RENDER ENGINE", style: GoogleFonts.getFont('Doto', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                  Row(children: [
                      OutlinedButton.icon(onPressed: _importPreset, icon: const Icon(Icons.download, size: 18), label: const Text("IMPORT")),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(onPressed: _exportPreset, icon: const Icon(Icons.upload, size: 18), label: const Text("EXPORT")),
                  ])
              ]),
              const SizedBox(height: 32),
              
              _slider("Shadow Quality", "Shadows", 0, 4, divisions: 4),
              _slider("Bloom Intensity", "Bloom", 0, 10, divisions: 10, label: "0=Off, 10=Max"),
              _slider("Anti-Aliasing", "AntiAliasing", 0, 4, divisions: 4),
              _slider("Water Quality", "Water", 0, 3, divisions: 3),
              _slider("Render Scale (%)", "RenderScale", 10, 200, divisions: 19),
              
              const Divider(color: Colors.white12, height: 48),
              
              _switch("Use Sunshafts (God Rays)", "UseSunshaft"),
              _switch("Depth of Field", "DepthOfField"), 
              _switch("Foliage Fading", "UseFoliageFading"),
              
              const SizedBox(height: 48),
              SizedBox(width: double.infinity, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0000), foregroundColor: Colors.white, padding: const EdgeInsets.all(20), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  onPressed: _saveConfig,
                  child: Text("SAVE CONFIGURATION", style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold))
              ))
          ]
      );
  }
  
  Widget _slider(String title, String key, double min, double max, {int? divisions, String? label}) {
      final val = (_renderSettings[key] ?? min).toDouble();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
             Text(title, style: const TextStyle(color: Colors.white70)),
             Text(val.toStringAsFixed(0), style: GoogleFonts.getFont('Doto', color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          Slider(
              value: val.clamp(min, max),
              min: min, max: max,
              divisions: divisions,
              activeColor: const Color(0xFFFF0000),
              inactiveColor: Colors.white10,
              onChanged: (v) => setState(() => _renderSettings[key] = v.toInt()) 
          ),
          if (label != null) Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 24),
      ]);
  }
  
  Widget _switch(String title, String key) {
      bool val = false;
      if (_renderSettings[key] is bool) val = _renderSettings[key];
      if (_renderSettings[key] is int) val = _renderSettings[key] > 0;
      
      return SwitchListTile(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          value: val,
          activeColor: const Color(0xFFFF0000),
          trackColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? const Color(0xFFFF0000).withOpacity(0.5) : Colors.black),
          thumbColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? const Color(0xFFFF0000) : Colors.grey),
          onChanged: (v) => setState(() {
              if (_renderSettings[key] is int) {
                  _renderSettings[key] = v ? 1 : 0;
              } else {
                  _renderSettings[key] = v;
              }
          })
      );
  }
}
