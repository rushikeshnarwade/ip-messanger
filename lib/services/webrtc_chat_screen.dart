import 'package:flutter/material.dart';
import 'package:ip_messanger/services/webrtc_service.dart';

class WebRTCChatScreen extends StatefulWidget {
  final String remotePeerId;
  final String currentUserId;

  const WebRTCChatScreen({
    Key? key,
    required this.remotePeerId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<WebRTCChatScreen> createState() => _WebRTCChatScreenState();
}

class _WebRTCChatScreenState extends State<WebRTCChatScreen> {
  late final WebRTCService _webRTCService;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    _webRTCService = WebRTCService(
      userId: widget.currentUserId,
      peerId: widget.remotePeerId,
    );

    await _webRTCService.initialize();

    // Listen to connection state changes
    _webRTCService.connectionState.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });

    // Listen to messages
    _webRTCService.messageStream.listen((message) {
      if (mounted) {
        setState(() => _messages.add(message));
      }
    });

    // Create the initial offer
    await _webRTCService.createOffer();

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (!_isConnected) {
      _showError('Not connected to peer. Please wait or try reconnecting.');
      return;
    }

    final success = await _webRTCService.sendMessage(message);
    if (success) {
      _messageController.clear();
    } else {
      _showError('Failed to send message. Please try again.');
    }
  }

  Future<void> _handleReconnect() async {
    try {
      setState(() => _isConnected = false);
      await _webRTCService.reconnect();
    } catch (e) {
      _showError('Failed to reconnect: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat'),
            Text(
              _isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleReconnect,
              tooltip: 'Reconnect',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_isInitialized) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isFromMe = message['from'] == widget.currentUserId;

                return Align(
                  alignment:
                      isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isFromMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['content'],
                      style: TextStyle(
                        color: isFromMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _webRTCService.dispose();
    super.dispose();
  }
}
