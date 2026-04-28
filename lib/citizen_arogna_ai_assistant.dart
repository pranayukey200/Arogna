import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CitizenArognaAIAssistant extends StatefulWidget {
  const CitizenArognaAIAssistant({Key? key}) : super(key: key);

  @override
  State<CitizenArognaAIAssistant> createState() => _CitizenArognaAIAssistantState();
}

class _CitizenArognaAIAssistantState extends State<CitizenArognaAIAssistant> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  List<Map<String, String>> messages = [
    {
      'role': 'assistant',
      'content': 'Arogna Emergency Assistant activated. How can I help you today?',
    }
  ];

  @override
  void initState() {
    super.initState();
    _checkActiveSos();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords; 
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _checkActiveSos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sos_events')
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          messages.add({
            'role': 'assistant',
            'content': 'I see your SOS is active. An ambulance is 4 minutes away. While you wait, keep the patient\'s head elevated and ensure the airway is clear.',
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error checking active SOS: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({'role': 'user', 'content': text});
      _controller.clear();
      isLoading = true;
    });
    
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are Arogna Emergency Assistant. Your primary goal is to provide immediate First Aid instructions (CPR, choking, bleeding, etc.) to users in high-stress emergency situations. Be extremely concise, use bullet points, and prioritize life-saving actions. Do not answer non-medical or non-emergency questions."
            },
            ...messages
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        setState(() {
          messages.add({'role': 'assistant', 'content': reply});
        });
      } else {
        setState(() {
          messages.add({'role': 'assistant', 'content': 'Error: Failed to connect to AI (Status ${response.statusCode}).'});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({'role': 'assistant', 'content': 'Error connecting to service: $e'});
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Widget _buildAssistantBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0059BB), // primary
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0059BB), // Arogna Blue
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(0),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F4F9), // Light Gray/Blue
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF001A41), // Deep Blue
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE5E8EE),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF717786), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0059BB),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E3E8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(0),
              ),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF), // background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: const Color(0x0D000000), // 0.05 opacity
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE5E8EE), // surface-container-high
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF717786)), // outline
          ),
        ),
        title: const Text(
          'Arogna',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFF0059BB), // blue-700
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0059BB)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 20),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildLoadingBubble();
                    }
                    final msg = messages[index];
                    if (msg['role'] == 'user') {
                      return _buildUserBubble(msg['content']!);
                    } else {
                      return _buildAssistantBubble(msg['content']!);
                    }
                  },
                ),
                // Persistent Call 112 Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call, color: Colors.white, size: 20),
                    label: const Text(
                      'CALL 112',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05 * 12,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6152E), // secondary
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0x40B6152E), // 0.25 opacity
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Input Area
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FF),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF), // surface-container-lowest
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E3E8)), // surface-container-highest
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000), // 0.05 opacity
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                      ),
                      onPressed: _listen,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (value) => sendMessage(value),
                        textInputAction: TextInputAction.send,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Type your message or use voice...',
                          hintStyle: TextStyle(color: Color(0xFFC1C6D7)), // outline-variant
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF181C20), // on-surface
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2, right: 2),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0059BB), // primary
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000), // small shadow
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => sendMessage(_controller.text),
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
