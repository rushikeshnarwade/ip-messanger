import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCException implements Exception {
  final String message;
  WebRTCException(this.message);
  @override
  String toString() => 'WebRTCException: $message';
}

class WebRTCService {
  final String userId;
  final String peerId;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  final _firestore = FirebaseFirestore.instance;

  final _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  RTCDataChannel? _dataChannel;
  bool _isConnected = false;
  bool _isDisposed = false;
  bool _isInitializing = false;

  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;

  WebRTCService({required this.userId, required this.peerId});

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      };

      peerConnection = await createPeerConnection(configuration);

      // Setup connection state change handler
      peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        _isConnected =
            state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
        _safeAddToConnectionState(_isConnected);
      };

      // Get local media stream
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });

      // Add local tracks to peer connection
      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });

      // Listen for remote tracks
      peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          // Handle remote stream
        }
      };

      // Handle ICE candidates
      peerConnection!.onIceCandidate = (candidate) async {
        if (!_isDisposed) {
          await _firestore
              .collection('connections')
              .doc('${userId}_$peerId')
              .collection('candidates')
              .add(candidate.toMap());
        }
      };

      // Setup data channel
      _dataChannel = await peerConnection!.createDataChannel(
        'messageChannel',
        RTCDataChannelInit()..ordered = true,
      );
      _setupDataChannel(_dataChannel!);

      peerConnection!.onDataChannel = (channel) {
        _dataChannel = channel;
        _setupDataChannel(channel);
      };

      _connectionStateController.add(false);
    } finally {
      _isInitializing = false;
    }
  }

  void _safeAddToMessageStream(Map<String, dynamic> message) {
    if (!_isDisposed && !_messageStreamController.isClosed) {
      _messageStreamController.add(message);
    }
  }

  void _safeAddToConnectionState(bool state) {
    if (!_isDisposed && !_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _setupDataChannel(RTCDataChannel channel) {
    channel.onMessage = (data) {
      if (data.type == MessageType.text) {
        _safeAddToMessageStream({
          'content': data.text,
          'from': peerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    };

    channel.onDataChannelState = (state) {
      _isConnected = state == RTCDataChannelState.RTCDataChannelOpen;
      _safeAddToConnectionState(_isConnected);
    };
  }

  bool isReadyForCommunication() {
    return _isConnected && _dataChannel != null;
  }

  Future<bool> sendMessage(String message) async {
    if (_isDisposed) return false;
    if (!isReadyForCommunication()) return false;

    try {
      await _dataChannel!.send(RTCDataChannelMessage(message));
      _safeAddToMessageStream({
        'content': message,
        'from': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> createOffer() async {
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await _firestore.collection('connections').doc('${userId}_$peerId').set({
      'offer': offer.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offer) async {
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    await _firestore.collection('connections').doc('${peerId}_$userId').set({
      'answer': answer.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> handleAnswer(Map<String, dynamic> answer) async {
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  Future<void> handleCandidate(Map<String, dynamic> candidate) async {
    await peerConnection!.addCandidate(
      RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ),
    );
  }

  Future<void> reconnect() async {
    dispose();
    await initialize();
    await createOffer();
  }

  void dispose() {
    _isDisposed = true;
    _dataChannel?.close();
    if (!_messageStreamController.isClosed) {
      _messageStreamController.close();
    }
    if (!_connectionStateController.isClosed) {
      _connectionStateController.close();
    }
    localStream?.dispose();
    peerConnection?.dispose();
  }
}
