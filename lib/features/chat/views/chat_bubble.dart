// lib/features/chat/views/chat_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'dart:async';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;

  const ChatBubble({
    Key? key,
    required this.message,
    this.isStreaming = false,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  Timer? _timer;
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isStreaming && widget.message.type == MessageType.bot) {
      _startTypingAnimation();
    } else {
      _displayedText = widget.message.content;
    }
  }

  void _startTypingAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.message.content.length) {
        setState(() {
          _displayedText += widget.message.content[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && widget.message.content != oldWidget.message.content) {
      // Mise à jour du contenu pendant le streaming
      setState(() {
        _displayedText = widget.message.content;
        _currentIndex = _displayedText.length;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.type == MessageType.user;
    final isError = widget.message.type == MessageType.error;
    final isLoading = widget.message.type == MessageType.loading;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: _getBubbleColor(isUser, isError),
          borderRadius: _getBorderRadius(isUser),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isLoading)
              const SizedBox(
                height: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF5B5FC7),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('En train d\'écrire...'),
                  ],
                ),
              )
            else
              Text(
                _displayedText,
                style: TextStyle(
                  color: isUser ? Colors.white : (isError ? Colors.red : const Color(0xFF1F2937)),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            if (!isLoading && widget.message.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.message.formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBubbleColor(bool isUser, bool isError) {
    if (isError) return const Color(0xFFFFF5F5);
    if (isUser) return const Color(0xFF5B5FC7);
    return Colors.white;
  }

  BorderRadius _getBorderRadius(bool isUser) {
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    }
  }
}