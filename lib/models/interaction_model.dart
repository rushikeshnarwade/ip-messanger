import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionModel {
  static List<InteractionModel> interactions = [];
  final String peerDeviceID;
  final String peerIP;
  final String? peerUsername;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  InteractionModel({
    required this.peerDeviceID,
    required this.peerIP,
    required this.peerUsername,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  InteractionModel.fromFirestore(Map<String, dynamic> data)
    : peerDeviceID = data['peerDeviceID'],
      peerIP = data['peerIP'],
      peerUsername = data['peerUsername'],
      lastMessage = data['lastMessage'],
      lastMessageTimestamp = data['lastMessageTimestamp'];

  Map<String, dynamic> toJson() {
    return {
      'peerDeviceID': peerDeviceID,
      'peerIP': peerIP,
      'peerUsername': peerUsername,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}
