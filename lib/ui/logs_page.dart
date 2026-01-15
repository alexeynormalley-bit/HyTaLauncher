import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/game_launcher.dart';
import 'package:hyta_launcher/services/server_manager.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("LOGS", style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildClientLogs(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClientLogs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.computer, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text('Game Client Output', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                  tooltip: 'Copy logs',
                  onPressed: () {
                    final logs = context.read<GameLauncher>().logs.join("\n");
                    Clipboard.setData(ClipboardData(text: logs));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Client logs copied")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
                  tooltip: 'Clear logs',
                  onPressed: () => context.read<GameLauncher>().clearLogs(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<GameLauncher>(
              builder: (context, launcher, _) {
                if (launcher.logs.isEmpty) {
                  return Center(
                    child: Text("No client logs available.\nLaunch the game to see output here.", 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(color: Colors.white24)),
                  );
                }
                return SelectionArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: launcher.logs.length,
                    itemBuilder: (context, index) {
                      final log = launcher.logs[index];
                      final isError = log.contains("[ERR]") || 
                                      log.toLowerCase().contains("error") || 
                                      log.toLowerCase().contains("exception");
                      return Text(
                        log,
                        style: GoogleFonts.robotoMono(
                          color: isError ? const Color(0xFFFF5555) : Colors.white, 
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
