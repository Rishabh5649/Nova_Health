import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final List<Message> _messages = [
    Message(text: "Hello! I'm Nova, your health assistant. How can I help you today?", isUser: false),
  ];
  final TextEditingController _ctrl = TextEditingController();
  bool _isOpen = false;

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _ctrl.clear();
    });

    // Mock AI response
    Future.delayed(const Duration(seconds: 1), () {
      String response = "I can help with that. Could you please provide more details?";
      final lower = text.toLowerCase();
      
      if ((lower.contains('booked') || lower.contains('appointment')) && (lower.contains('confirm') || lower.contains('status') || lower.contains('not'))) {
        response = "I see. If you haven't received a confirmation yet, please check your 'My Appointments' tab for the status. If it says 'Pending', the doctor is reviewing it. For urgent issues, you can call our support line at 1-800-NOVA-CARE.";
      } else if (lower.contains('appointment') || lower.contains('book')) {
        response = "You can book an appointment by tapping the 'Search' tab or browsing our specialists.";
      } else if (lower.contains('prescription') || lower.contains('medicine')) {
        response = "You can view your prescriptions in the 'Prescriptions' section on the dashboard.";
      } else if (lower.contains('insurance') || lower.contains('coverage')) {
        response = "We offer various insurance plans starting from \$10/mo. Check the 'Health Insurance' section.";
      } else if (lower.contains('premium') || lower.contains('plan')) {
        response = "Our Premium plans offer 0 fees and priority support. Check 'Buy Premium' in the menu.";
      } else if (lower.contains('hello') || lower.contains('hi')) {
        response = "Hi there! How can I assist you with your health needs today?";
      }

      if (mounted) {
        setState(() {
          _messages.add(Message(text: response, isUser: false));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOpen) {
      return FloatingActionButton(
        onPressed: () => setState(() => _isOpen = true),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      );
    }

    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Nova Assistant', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _isOpen = false),
                ),
              ],
            ),
          ),
          
          // Chat Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF6366F1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(0),
                      ),
                    ),
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      msg.text,
                      style: GoogleFonts.poppins(
                        color: msg.isUser ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}
