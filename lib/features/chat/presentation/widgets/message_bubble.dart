import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.isMe = true,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isPlayingAudio = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message;
    final isMe = widget.isMe;
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    final bubbleColor = isMe
        ? (theme.brightness == Brightness.dark
            ? const Color(0xFF005C4B) // WhatsApp dark green
            : const Color(0xFFD9FDD3)) // WhatsApp light green
        : (theme.brightness == Brightness.dark
            ? const Color(0xFF202C33)
            : Colors.white);

    final textColor = isMe
        ? (theme.brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF111B21))
        : (theme.brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF111B21));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Content: Text, Image, Video, or Voice Note
              if (message.type == MessageType.image) ...[
                _buildImageContent(message.text),
                const SizedBox(height: 4),
              ] else if (message.type == MessageType.video) ...[
                _buildVideoContent(),
                const SizedBox(height: 4),
              ] else if (message.type == MessageType.audio) ...[
                _buildAudioContent(textColor),
                const SizedBox(height: 4),
              ] else ...[
                Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
              ],

              // Timestamp & Status Ticks
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: message.status == MessageStatus.read
                          ? const Color(0xFF53BDEB) // WhatsApp blue ticks
                          : textColor.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(String source) {
    Widget imageWidget;
    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 240,
          height: 200,
        );
      } catch (_) {
        imageWidget = const SizedBox(
          width: 200,
          height: 140,
          child: Icon(Icons.broken_image, size: 48),
        );
      }
    } else if (source.startsWith('http')) {
      imageWidget = Image.network(
        source,
        fit: BoxFit.cover,
        width: 240,
        height: 200,
        errorBuilder: (_, _, _) => const SizedBox(
          width: 200,
          height: 140,
          child: Icon(Icons.broken_image, size: 48),
        ),
      );
    } else {
      imageWidget = Container(
        width: 200,
        height: 140,
        color: Colors.black12,
        child: const Icon(Icons.image, size: 48),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );
  }

  Widget _buildVideoContent() {
    return Container(
      width: 240,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.videocam, size: 64, color: Colors.white24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
          ),
          const Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              'Video',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(Color textColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 40,
              color: widget.isMe ? const Color(0xFF00A884) : Colors.deepPurple,
            ),
            onPressed: () => setState(() => _isPlayingAudio = !_isPlayingAudio),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform simulation bars
                Row(
                  children: List.generate(14, (i) {
                    final height = [8.0, 16.0, 12.0, 20.0, 14.0, 18.0, 10.0, 22.0, 16.0, 12.0, 18.0, 14.0, 10.0, 6.0][i];
                    return Expanded(
                      child: Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: (_isPlayingAudio && i < 8)
                              ? const Color(0xFF00A884)
                              : textColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlayingAudio ? 'Playing…' : '0:12 • Voice note',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.mic, size: 16, color: textColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
