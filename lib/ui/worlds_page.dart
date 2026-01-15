import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
                  const Icon(Icons.public, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'World Manager',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _importWorld,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Import World'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => worldManager.refreshWorlds(),
                    icon: const Icon(Icons.refresh),
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        worldManager.universePath,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
                  ? const Center(child: CircularProgressIndicator())
                  : worldManager.worlds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'No worlds found',
                                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a world in game or import one',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: worldManager.worlds.length,
                          itemBuilder: (context, index) {
                            final world = worldManager.worlds[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Icon(Icons.terrain, color: Colors.white),
                                ),
                                title: Text(
                                  world.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${worldManager.formatSize(world.sizeBytes)} • ${world.lastModified?.toString().substring(0, 19) ?? "Unknown date"}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.folder_open),
                                      tooltip: 'Open Folder',
                                      onPressed: () => worldManager.openWorldFolder(world.name),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.file_upload),
                                      tooltip: 'Export',
                                      onPressed: () => _exportWorld(world),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
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
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(worldManager.error!, style: const TextStyle(color: Colors.white))),
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
