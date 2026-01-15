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

class _LogsPageState extends State<LogsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commandController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("LOGS", style: GoogleFonts.getFont('Doto', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 24),
              
              SizedBox(
                width: 300,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'CLIENT'),
                    Tab(text: 'SERVER'),
                  ],
                ),
              ),
              
              const Spacer(),
              
              Consumer<ServerManager>(
                builder: (context, serverManager, _) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('EXPERIMENTAL', 
                          style: GoogleFonts.robotoMono(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      if (serverManager.isRunning)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, color: Colors.green, size: 10),
                              const SizedBox(width: 6),
                              Text('Port ${serverManager.serverPort}', 
                                style: GoogleFonts.robotoMono(color: Colors.green, fontSize: 12)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: serverManager.isRunning ? Colors.red.shade900 : Colors.green.shade800,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () {
                          if (serverManager.isRunning) {
                            serverManager.stopServer();
                          } else {
                            serverManager.startServer();
                            _tabController.animateTo(1);
                          }
                        },
                        icon: Icon(serverManager.isRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(serverManager.isRunning ? 'STOP SERVER' : 'START SERVER',
                          style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClientLogs(),
                _buildServerLogs(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClientLogs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
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
  
  Widget _buildServerLogs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dns, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text('HytaleServer Output', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                  tooltip: 'Copy logs',
                  onPressed: () {
                    final logs = context.read<ServerManager>().logs.join("\n");
                    Clipboard.setData(ClipboardData(text: logs));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Server logs copied")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
                  tooltip: 'Clear logs',
                  onPressed: () => context.read<ServerManager>().clearLogs(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ServerManager>(
              builder: (context, serverManager, _) {
                if (serverManager.logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dns, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text("Server logs will appear here", 
                          style: GoogleFonts.robotoMono(color: Colors.white24)),
                        const SizedBox(height: 8),
                        Text("Click 'START SERVER' to launch", 
                          style: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                  );
                }
                return SelectionArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: serverManager.logs.length,
                    itemBuilder: (context, index) {
                      final log = serverManager.logs[index];
                      final isError = log.contains("[ERR]") || 
                                      log.contains("SEVERE") ||
                                      log.toLowerCase().contains("error") || 
                                      log.toLowerCase().contains("exception");
                      final isWarn = log.contains("WARN");
                      final isInfo = log.contains("INFO");
                      
                      Color color = Colors.white;
                      if (isError) color = const Color(0xFFFF5555);
                      else if (isWarn) color = Colors.orange;
                      else if (isInfo) color = Colors.white70;
                      
                      return Text(
                        log,
                        style: GoogleFonts.robotoMono(color: color, fontSize: 11),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          Consumer<ServerManager>(
            builder: (context, serverManager, _) {
              if (!serverManager.isRunning) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white24)),
                ),
                child: Row(
                  children: [
                    Text('>', style: GoogleFonts.robotoMono(color: Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter server command...',
                          hintStyle: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (cmd) {
                          if (cmd.isNotEmpty) {
                            serverManager.sendCommand(cmd);
                            _commandController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, size: 16, color: Colors.green),
                      onPressed: () {
                        if (_commandController.text.isNotEmpty) {
                          serverManager.sendCommand(_commandController.text);
                          _commandController.clear();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
