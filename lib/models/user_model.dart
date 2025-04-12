import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String username;
  final String uid;
  final String ipAddress;
  final DateTime lastSeen;
  final String email;

  static UserModel? currentUser;

  UserModel(this.username, this.ipAddress, this.lastSeen, this.uid, this.email);

  UserModel.fromFirestore(Map<String, dynamic> data)
    : username = data['username'],
      ipAddress = data['ipAddress'],
      lastSeen = data['lastSeen'].toDate(),
      uid = data['uid'],
      email = data['email'];

  Map<String, dynamic> toJSON() {
    return {
      'username': username,
      'ipAddress': ipAddress,
      'lastSeen': FieldValue.serverTimestamp(),
      'uid': uid,
      'email': email,
    };
  }
}
