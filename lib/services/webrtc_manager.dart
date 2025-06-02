import 'package:cloud_firestore/cloud_firestore.dart';
import 'webrtc_service.dart';

class WebRTCManager {
  final String currentUserId;
  final _connections = <String, WebRTCService>{};
  final _firestore = FirebaseFirestore.instance;
  bool _isPaused = false;

  WebRTCManager({required this.currentUserId});

  Future<void> initialize() async {
    // Listen for connection requests
    _firestore
        .collection('connections')
        .where('receiver', isEqualTo: currentUserId)
        .snapshots()
        .listen(_handleConnectionRequest);
  }

  void _handleConnectionRequest(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>;
        final senderId = data['sender'] as String;

        if (!_connections.containsKey(senderId)) {
          _createConnection(senderId);
        }

        if (data['offer'] != null) {
          _connections[senderId]?.handleOffer(data['offer']);
        } else if (data['answer'] != null) {
          _connections[senderId]?.handleAnswer(data['answer']);
        }
      }
    }
  }

  Future<WebRTCService> _createConnection(String peerId) async {
    final service = WebRTCService(userId: currentUserId, peerId: peerId);

    await service.initialize();
    _connections[peerId] = service;

    // Listen for ICE candidates
    _firestore
        .collection('connections')
        .doc('${peerId}_$currentUserId')
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              service.handleCandidate(change.doc.data()!);
            }
          }
        });

    return service;
  }

  Future<WebRTCService?> getConnection(String peerId) async {
    if (_isPaused) return null; // Don't create new connections while paused

    if (!_connections.containsKey(peerId)) {
      await _createConnection(peerId);
    }
    return _connections[peerId];
  }

  void dispose() {
    for (var connection in _connections.values) {
      connection.dispose();
    }
    _connections.clear();
  }

  void handleAppPause() {
    _isPaused = true;
    _updateOnlineStatus(false);
    // Pause all active connections
    for (var connection in _connections.values) {
      connection.dispose();
    }
    _connections.clear();
  }

  void handleAppResume() {
    _isPaused = false;
    _updateOnlineStatus(true);
    // Reconnect all active connections
    for (var connection in _connections.values) {
      connection.reconnect();
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
