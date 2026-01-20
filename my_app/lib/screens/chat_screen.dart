import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import '../services/gemini_service.dart';

// Custom physics for that "slick" feel
const Curve kOutToRice = Cubic(0.23, 1, 0.32, 1);

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final List<ChatMessage> messages = [];
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;

  // Animation controller for the moving background gradients
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slow, ethereal movement
    )..repeat(reverse: true);
  }

  void addMessage(String text, bool isUser) {
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isUserMessage: isUser,
        timestamp: DateTime.now(),
      ));
    });
    scrollToBottom();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 800),
          curve: kOutToRice,
        );
      }
    });
  }

  Future<void> handleSend(String text) async {
    if (text.trim().isEmpty) return;
    addMessage(text, true);
    setState(() => isTyping = true);

    try {
      final aiResponse = await GeminiService.sendMessage(text);
      setState(() => isTyping = false);
      addMessage(aiResponse, false);
    } catch (e) {
      setState(() => isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('System Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12), // Pitch black-blue
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: scrollController,
                  reverse: true, // Key for chat: latest at bottom
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 30),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Reverse indexing for the 'reverse: true' list
                    final message = messages[messages.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: MessageBubble(message: message),
                    );
                  },
                ),
              ),
              if (isTyping) _buildTypingIndicator(),
              _buildInputSection(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.black.withOpacity(0.2),
            centerTitle: true,
            title: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent],
                  ).createShader(bounds),
                  child: const Text(
                    'GEMINI CORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isTyping ? Colors.cyanAccent : Colors.greenAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isTyping ? Colors.cyanAccent : Colors.greenAccent,
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTyping ? "SYNCING..." : "CONNECTED",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            // Blue Blob
            Positioned(
              top: -150 + (100 * _bgController.value),
              right: -100 + (50 * _bgController.value),
              child: _buildBlurCircle(400, Colors.blueAccent.withOpacity(0.12)),
            ),
            // Purple Blob
            Positioned(
              bottom: -100 + (80 * _bgController.value),
              left: -100 + (70 * _bgController.value),
              child: _buildBlurCircle(350, Colors.purpleAccent.withOpacity(0.1)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Neural processing...",
          style: TextStyle(color: Colors.cyanAccent.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InputBar(onSendMessage: handleSend),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing Pulsing Orb
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOutSine,
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.15),
                        blurRadius: 50,
                        spreadRadius: 10,
                      )
                    ],
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1E2632), Color(0xFF0B0D12)],
                    ),
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 60, color: Colors.cyanAccent),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            'SYSTEM READY',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
          ),
          const SizedBox(height: 12),
          Text(
            'Establish neural link to begin.',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}