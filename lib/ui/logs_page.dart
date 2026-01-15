import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyta_launcher/services/game_launcher.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text("GAME LOGS", style: GoogleFonts.getFont('Doto', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    
                    ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () {
                            final logs = context.read<GameLauncher>().logs.join("\n");
                            Clipboard.setData(ClipboardData(text: logs));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logs copied to clipboard")));
                        },
                        icon: const Icon(Icons.copy),
                        label: Text("COPY LOGS", style: GoogleFonts.getFont('Doto', fontWeight: FontWeight.bold))
                    )
                ],
            ),
            const SizedBox(height: 16),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFF101010),
                        border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Consumer<GameLauncher>(
                        builder: (context, launcher, _) {
                            if (launcher.logs.isEmpty) {
                                return Center(child: Text("No logs available.", style: GoogleFonts.robotoMono(color: Colors.white24)));
                            }
                            return SelectionArea(
                                child: ListView.builder(
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
                                                fontSize: 12
                                            ),
                                        );
                                    },
                                ),
                            );
                        }
                    )
                )
            )
        ],
      )
    );
  }
}
