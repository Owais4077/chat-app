import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/chat_message.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    this.onSendMedia,
  });

  final ValueChanged<String> onSend;
  final void Function(String mediaUrl, MessageType type)? onSendMedia;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  bool _canSend = false;
  bool _isRecordingVoice = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _canSend) {
        setState(() => _canSend = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _voiceTimer?.cancel();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (widget.onSendMedia != null) {
        widget.onSendMedia!(base64String, MessageType.image);
      } else {
        widget.onSend(base64String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      final fakeVideoUrl = 'video://${file.name}';
      if (widget.onSendMedia != null) {
        widget.onSendMedia!(fakeVideoUrl, MessageType.video);
      } else {
        widget.onSend(fakeVideoUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick video: $e')),
        );
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Media',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MediaOption(
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    label: 'Gallery Photo',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage();
                    },
                  ),
                  _MediaOption(
                    icon: Icons.videocam,
                    color: Colors.pink,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickVideo();
                    },
                  ),
                  _MediaOption(
                    icon: Icons.mic,
                    color: const Color(0xFF00A884),
                    label: 'Voice Note',
                    onTap: () {
                      Navigator.pop(ctx);
                      _startVoiceRecording();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecordingVoice = true;
      _voiceSeconds = 0;
    });
    _voiceTimer?.cancel();
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _voiceSeconds++);
      }
    });
  }

  void _cancelVoiceRecording() {
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _voiceSeconds = 0;
    });
  }

  void _sendVoiceRecording() {
    _voiceTimer?.cancel();
    final durationStr = '0:${_voiceSeconds.toString().padLeft(2, '0')}';
    final voicePayload = 'audio://voice-note-$durationStr';
    setState(() {
      _isRecordingVoice = false;
      _voiceSeconds = 0;
    });
    if (widget.onSendMedia != null) {
      widget.onSendMedia!(voicePayload, MessageType.audio);
    } else {
      widget.onSend(voicePayload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Voice recording mode UI
    if (_isRecordingVoice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Text(
              '0:${_voiceSeconds.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Recording audio note…',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Cancel',
              onPressed: _cancelVoiceRecording,
            ),
            IconButton.filled(
              icon: const Icon(Icons.send, size: 20),
              tooltip: 'Send voice note',
              onPressed: _sendVoiceRecording,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, size: 24),
              tooltip: 'Attach photo, video or voice',
              onPressed: _showAttachmentMenu,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Record voice note',
              icon: const Icon(Icons.mic, size: 22, color: Color(0xFF00A884)),
              onPressed: _startVoiceRecording,
            ),
            Semantics(
              label: 'Send message',
              button: true,
              child: IconButton.filled(
                tooltip: 'Send message',
                onPressed: _send,
                icon: const Icon(Icons.send, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  const _MediaOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
