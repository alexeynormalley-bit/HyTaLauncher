import 'package:hyta_launcher/services/server_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyta_launcher/services/ai_service.dart';
import 'package:hyta_launcher/services/game_launcher.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final AiService _aiService = AiService();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  List<Map<String, String>> _messages = []; 
  bool _showSettings = false;
  
  String _actionText = "";
  IconData? _actionIcon;
  bool _showAction = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }
  
  void _triggerActionFeedback(String text, IconData icon) async {
      setState(() {
          _actionText = text;
          _actionIcon = icon;
          _showAction = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _showAction = false);
  }

  Future<void> _initService() async {
    await _aiService.init();
    setState(() {
        _apiKeyController.text = _aiService.apiKey ?? "";
    });
  }

  Future<void> _sendMessage() async {
      final text = _inputController.text.trim();
      if (text.isEmpty) return;

      if (_apiKeyController.text.isEmpty) {
          setState(() => _showSettings = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your Gemini API Key first.")));
          return;
      }
      
      if (_apiKeyController.text != _aiService.apiKey) {
          await _aiService.setApiKey(_apiKeyController.text);
      }

      setState(() {
          _messages.add({"role": "user", "text": text});
          _isLoading = true;
          _inputController.clear();
      });
      _scrollToBottom();
      
      _triggerActionFeedback("ANALYZING LOGS & CONTEXT...", Icons.analytics_outlined);

      final clientLogs = context.read<GameLauncher>().logs;
      final serverLogs = context.read<ServerManager>().logs;
      final response = await _aiService.sendMessage(text, clientLogs, serverLogs);
      
      if (response.contains("[SET_")) {
          _handleInjection(response);
      }

      setState(() {
          _messages.add({"role": "ai", "text": response});
          _isLoading = false;
      });
      _scrollToBottom();
  }
  
  void _handleInjection(String response) async {
      final prefs = await SharedPreferences.getInstance();
      bool changed = false;

      final ramExp = RegExp(r'\[SET_RAM\] (\d+)');
      final ramMatch = ramExp.firstMatch(response);
      if (ramMatch != null) {
          final val = ramMatch.group(1);
          await prefs.setString('max_ram', val!);
          _triggerActionFeedback("UPDATED RAM: $val MB", Icons.memory);
          changed = true;
      }

      final flagExp = RegExp(r'\[SET_FLAGS\] (.*)');
      final flagMatch = flagExp.firstMatch(response);
      if (flagMatch != null) {
          final val = flagMatch.group(1);
          await prefs.setString('custom_flags', val!);
          _triggerActionFeedback("UPDATED FLAGS: $val", Icons.flag);
          changed = true;
      }
      
      final javaExp = RegExp(r'\[SET_JAVA\] (.*)');
      final javaMatch = javaExp.firstMatch(response);
      if (javaMatch != null) {
          final val = javaMatch.group(1);
          await prefs.setString('java_path', val!); 
          _triggerActionFeedback("UPDATED JAVA: $val", Icons.coffee);
          changed = true;
      }

      if (changed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings updated by AI. Restart required to take effect.")));
      }
  }

  void _scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
              _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
              );
          }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Stack(
        children: [
          Column(
            children: [
                Row(
                    children: [
                        Text("AI ASSISTANT", style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Spacer(),
                        IconButton(
                            onPressed: () => setState(() => _showSettings = !_showSettings),
                            icon: Icon(_showSettings ? Icons.close : Icons.settings, color: Colors.white)
                        )
                    ],
                ),
            
            if (_showSettings) ...[
                const SizedBox(height: 16),
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text("GEMINI API KEY", style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                                controller: _apiKeyController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    hintText: "Enter key...",
                                    hintStyle: const TextStyle(color: Colors.white24),
                                    filled: true,
                                    fillColor: const Color(0xFF050505),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12))
                                ),
                                onChanged: (v) => _aiService.setApiKey(v),
                            ),
                            const SizedBox(height: 16),
                            Text("MODEL", style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                                value: _aiService.currentModel,
                                dropdownColor: Colors.black,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(filled: true, fillColor: const Color(0xFF050505), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12))),
                                items: AiService.availableModels.map((m) => 
                                    DropdownMenuItem(value: m, child: Text(m))
                                ).toList(),
                                onChanged: (v) {
                                    if (v != null) {
                                        _aiService.setModel(v);
                                        setState(() {});
                                    }
                                }
                            )
                        ],
                    ),
                )
            ],

            const SizedBox(height: 16),
            
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16)
                    ),
                    child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg['role'] == 'user';
                            return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                    constraints: const BoxConstraints(maxWidth: 600),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: isUser ? const Color(0xFF202020) : const Color(0xFF101010),
                                        border: Border.all(color: isUser ? Colors.white24 : Colors.white12),
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(isUser ? "YOU" : "AI", style: GoogleFonts.roboto(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            isUser 
                                                ? Text(msg['text']!, style: GoogleFonts.roboto(color: Colors.white))
                                                : MarkdownBody(
                                                    data: msg['text']!,
                                                    styleSheet: MarkdownStyleSheet(
                                                        p: GoogleFonts.roboto(color: Colors.white),
                                                        code: GoogleFonts.robotoMono(backgroundColor: Colors.white10),
                                                        codeblockDecoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  )
                                        ],
                                    )
                                )
                            );
                        }
                    ),
                )
            ),
            
            const SizedBox(height: 16),
            Row(
                children: [
                    Expanded(
                        child: TextField(
                            controller: _inputController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                                hintText: "Ask AI for help...",
                                hintStyle: const TextStyle(color: Colors.white24),
                                filled: true,
                                fillColor: const Color(0xFF101010),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: const BorderSide(color: Colors.white24))
                            ),
                            onSubmitted: (_) => _sendMessage(),
                        )
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                        height: 50,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12)
                            ),
                            onPressed: _isLoading ? null : _sendMessage,
                            child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                                : const Icon(Icons.arrow_upward)
                        )
                    )
                ],
            )
          ],
        ),
          
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutBack,
              right: 0,
              top: _showAction ? 60 : -100, 
              child: Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Row(
                      children: [
                          if (_actionIcon != null) ...[
                              Icon(_actionIcon, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                          ],
                          Expanded(
                              child: Text(
                                  _actionText,
                                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                              )
                          ),
                          const SizedBox(width: 8),
                          if (_showAction)
                            const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      ],
                  ),
              )
          )
        ],
      ),
    );
  }
}
