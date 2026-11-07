import 'dart:async';
import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.contactName,
    required this.isVideo,
  });

  final String contactName;
  final bool isVideo;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  int _seconds = 0;
  Timer? _callTimer;
  Timer? _connectSimulationTimer;

  @override
  void initState() {
    super.initState();
    // Simulate connection after 2 seconds
    _connectSimulationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isConnected = true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _connectSimulationTimer?.cancel();
    _callTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101D24),
      body: SafeArea(
        child: Stack(
          children: [
            // Video / Audio Main Display
            if (widget.isVideo && !_isCameraOff) ...[
              // Simulated Remote Video Feed
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F2C34), Color(0xFF0C1317)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF00A884).withValues(alpha: 0.2),
                        child: Text(
                          widget.contactName.isNotEmpty
                              ? widget.contactName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 48, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isConnected ? 'Video Call Connected' : 'Connecting video…',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              // PiP Local Video Preview
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.white54, size: 36),
                        SizedBox(height: 4),
                        Text('You', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Voice Call Display
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00A884).withValues(alpha: 0.15),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF00A884),
                        child: Text(
                          widget.contactName.isNotEmpty
                              ? widget.contactName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 46, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.contactName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConnected ? _formatDuration(_seconds) : 'Ringing…',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isConnected ? const Color(0xFF25D366) : Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Top Header: Contact Name & Status
            Positioned(
              top: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        widget.isVideo ? Icons.videocam : Icons.call,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected
                            ? '${widget.isVideo ? "Relay Video" : "Relay Voice"} • ${_formatDuration(_seconds)}'
                            : 'Ringing…',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Call Controls Bar
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speaker
                  _CallActionButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    isActive: _isSpeakerOn,
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                  // Mute Mic
                  _CallActionButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Muted' : 'Mute',
                    isActive: _isMuted,
                    activeColor: Colors.orange,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // Camera Toggle (if video call)
                  if (widget.isVideo)
                    _CallActionButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _isCameraOff ? 'Cam Off' : 'Cam On',
                      isActive: _isCameraOff,
                      activeColor: Colors.orange,
                      onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                    ),
                  // End Call Button
                  FloatingActionButton(
                    heroTag: 'endCallBtn',
                    backgroundColor: Colors.redAccent,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (activeColor ?? Colors.white)
                  : Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
