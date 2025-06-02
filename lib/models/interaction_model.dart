import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionModel {
  static List<InteractionModel> interactions = [];
  final String peerDeviceID;
  final String peerIP;
  final String? peerUsername;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final bool isOnline;
  final Map<String, dynamic>? connectionInfo;
  final int unreadCount;

  InteractionModel({
    required this.peerDeviceID,
    required this.peerIP,
    required this.peerUsername,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    this.isOnline = false,
    this.connectionInfo,
    this.unreadCount = 0,
  });

  InteractionModel.fromFirestore(Map<String, dynamic> data)
    : peerDeviceID = data['peerDeviceID'],
      peerIP = data['peerIP'],
      peerUsername = data['peerUsername'],
      lastMessage = data['lastMessage'],
      lastMessageTimestamp = data['lastMessageTimestamp'],
      isOnline = data['isOnline'] ?? false,
      connectionInfo = data['connectionInfo'],
      unreadCount = data['unreadCount'] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'peerDeviceID': peerDeviceID,
      'peerIP': peerIP,
      'peerUsername': peerUsername,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'isOnline': isOnline,
      'connectionInfo': connectionInfo,
      'unreadCount': unreadCount,
    };
  }
}
