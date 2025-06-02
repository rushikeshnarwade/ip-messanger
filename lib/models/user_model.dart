import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String username;
  final String id;
  final String ipAddress;
  final DateTime lastSeen;
  final String email;
  final String? photoUrl;
  bool isOnline;
  Map<String, dynamic>? connectionInfo;

  static UserModel? currentUser;

  UserModel(
    this.username,
    this.ipAddress,
    this.lastSeen,
    this.id,
    this.email,
    this.isOnline,
    this.photoUrl,
  );

  UserModel.fromFirestore(Map<String, dynamic> data)
    : username = data['username'],
      ipAddress = data['ipAddress'],
      lastSeen = data['lastSeen'].toDate(),
      id = data['uid'],
      email = data['email'],
      isOnline = data['isOnline'] ?? false,
      photoUrl = data['photoUrl'];

  Map<String, dynamic> toJSON() {
    return {
      'username': username,
      'ipAddress': ipAddress,
      'lastSeen': FieldValue.serverTimestamp(),
      'uid': id,
      'email': email,
      'isOnline': isOnline,
      'photoUrl': photoUrl,
      'connectionInfo': connectionInfo,
    };
  }
}
