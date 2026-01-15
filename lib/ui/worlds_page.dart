import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/world_manager.dart';

class WorldsPage extends StatefulWidget {
  const WorldsPage({super.key});

  @override
  State<WorldsPage> createState() => _WorldsPageState();
}

class _WorldsPageState extends State<WorldsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorldManager>().refreshWorlds();
    });
  }

  Future<void> _importWorld() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Select World Archive',
    );
    
    if (result != null && result.files.single.path != null) {
      final worldManager = context.read<WorldManager>();
      final success = await worldManager.importWorld(result.files.single.path!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'World imported successfully!' : 'Failed to import world: ${worldManager.error}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportWorld(WorldInfo world) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export World',
      fileName: '${world.name}.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    
    if (result != null) {
      final worldManager = context.read<WorldManager>();
      final success = await worldManager.exportWorld(world.name, result);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'World exported to $result' : 'Failed to export: ${worldManager.error}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWorld(WorldInfo world) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete World'),
        content: Text('Are you sure you want to delete "${world.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final worldManager = context.read<WorldManager>();
      final success = await worldManager.deleteWorld(world.name);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'World "${world.name}" deleted' : 'Failed to delete: ${worldManager.error}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorldManager>(
      builder: (context, worldManager, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.public, size: 28, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'World Manager',
                    style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _importWorld,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Import World'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => worldManager.refreshWorlds(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        worldManager.universePath,
                        style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: worldManager.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : worldManager.worlds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_open, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                'No worlds found',
                                style: GoogleFonts.roboto(fontSize: 18, color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a world in game or import one',
                                style: GoogleFonts.roboto(color: Colors.white24),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: worldManager.worlds.length,
                          itemBuilder: (context, index) {
                            final world = worldManager.worlds[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF101010),
                                  border: Border.all(color: Colors.white12),
                                  borderRadius: BorderRadius.circular(16)
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.white10,
                                  child: Icon(Icons.terrain, color: Colors.white),
                                ),
                                title: Text(
                                  world.name,
                                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${worldManager.formatSize(world.sizeBytes)} • ${world.lastModified?.toString().substring(0, 19) ?? "Unknown date"}',
                                  style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.folder_open, color: Colors.white70),
                                      tooltip: 'Open Folder',
                                      onPressed: () => worldManager.openWorldFolder(world.name),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.file_upload, color: Colors.white70),
                                      tooltip: 'Export',
                                      onPressed: () => _exportWorld(world),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white54),
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteWorld(world),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            if (worldManager.error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF200000), // Dark red background for errors
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5))
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(worldManager.error!, style: GoogleFonts.roboto(color: Colors.red[100]))),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
