import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ip_messanger/pages/home_page/widgets/drawer.dart';
import 'package:ip_messanger/pages/home_page/widgets/interaction_list.dart';
import 'package:ip_messanger/services/webrtc_chat_screen.dart';
import 'package:ip_messanger/services/webrtc_manager.dart';
import 'package:ip_messanger/pages/user_search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final WebRTCManager _webRTCManager;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebRTC();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      _webRTCManager.handleAppResume();
    } else if (state == AppLifecycleState.paused && !_isDisposed) {
      _webRTCManager.handleAppPause();
    }
  }

  Future<void> _initializeWebRTC() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !_isDisposed) {
        _webRTCManager = WebRTCManager(currentUserId: currentUser.uid);
        await _webRTCManager.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to initialize: $e')));
      }
    }
  }

  void _navigateToChat(String remotePeerId) {
    if (!_isInitialized) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WebRTCChatScreen(
              remotePeerId: remotePeerId,
              currentUserId: FirebaseAuth.instance.currentUser!.uid,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('IP Messenger')),
        body:
            _isInitialized
                ? InteractionList(onUserTap: _navigateToChat)
                : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing...'),
                    ],
                  ),
                ),
        drawer: const HomePageDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserSearchPage()),
            );
          },
          child: const Icon(Icons.chat),
          tooltip: 'Start new chat',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _webRTCManager.dispose();
    }
    super.dispose();
  }
}
