import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hyta_launcher/services/texture_manager.dart';
import 'package:hyta_launcher/services/game_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class TexturesPage extends StatefulWidget {
  const TexturesPage({super.key});

  @override
  State<TexturesPage> createState() => _TexturesPageState();
}

class _TexturesPageState extends State<TexturesPage> {
  late TextureManager _manager;
  bool _initialized = false;
  String _searchQuery = "";
  String _assetsPath = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final gameDir = context.read<GameLauncher>().gameDir;
       _assetsPath = p.join(gameDir, 'Assets');
       _manager = TextureManager(gameDir);
       _manager.scanTextures();
       setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _importPack() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null) {
      try {
        await _manager.importTexturePack(result.files.single.path!);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Texture Pack Imported!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator(color: Colors.white));

    return ChangeNotifierProvider.value(
      value: _manager,
      child: Consumer<TextureManager>(
        builder: (context, manager, _) {
          if (manager.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
          
          final filtered = manager.textureFiles.where((f) => 
             p.basename(f.path).toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _assetsPath.isEmpty ? "Game not installed yet" : _assetsPath,
                          style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                     Expanded(
                       child: TextField(
                         style: const TextStyle(color: Colors.white),
                         decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.white54),
                            hintText: "Search textures...",
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF101010),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: const BorderSide(color: Colors.white24))
                         ),
                         onChanged: (v) => setState(() => _searchQuery = v),
                       )
                     ),
                     const SizedBox(width: 16),
                     ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text("IMPORT ZIP"),
                        onPressed: _importPack,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           foregroundColor: Colors.black,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))
                        ),
                     )
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty 
                    ? Center(child: Text(_assetsPath.isEmpty ? "Install the game first to manage textures." : "No textures found in Assets folder.", style: GoogleFonts.roboto(color: Colors.white54)))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                           crossAxisCount: 6,
                           crossAxisSpacing: 8,
                           mainAxisSpacing: 8
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _TextureTile(file: filtered[i], manager: manager),
                      ),
                )
              ],
            ),
          );
        }
      ),
    );
  }
}

class _TextureTile extends StatelessWidget {
  final File file;
  final TextureManager manager;

  const _TextureTile({required this.file, required this.manager});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: manager.hasBackup(file),
      builder: (context, snapshot) {
        final hasBackup = snapshot.data ?? false;
        
        return InkWell(
          onTap: () => _showOptions(context, hasBackup),
          child: Container(
            decoration: BoxDecoration(
               color: const Color(0xFF151515),
               border: hasBackup ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.white12),
               borderRadius: BorderRadius.circular(12)
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.white12))
                ),
                Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Text(p.basename(file.path), 
                           style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 10),
                           textAlign: TextAlign.center,
                           overflow: TextOverflow.ellipsis
                        )
                    )
                ),
                if (hasBackup)
                   const Positioned(top: 4, right: 4, child: Icon(Icons.history, color: Colors.white, size: 16)),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showOptions(BuildContext context, bool hasBackup) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white)),
          title: Text(p.basename(file.path), style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                SizedBox(height: 100, child: Image.file(file)),
                const SizedBox(height: 16),
                if (hasBackup)
                   ElevatedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text("RESTORE ORIGINAL"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                          Navigator.pop(ctx);
                          await manager.restoreBackup(file);
                          // Refresh logic usually handled by manager notify
                      },
                   ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                   icon: const Icon(Icons.edit),
                   label: const Text("REPLACE TEXTURE"),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                   onPressed: () async {
                       Navigator.pop(ctx);
                       final result = await FilePicker.platform.pickFiles(type: FileType.image);
                       if (result != null) {
                           await manager.replaceTexture(file, result.files.single.path!);
                       }
                   },
                )
             ],
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white54)))
          ],
      ));
  }
}
