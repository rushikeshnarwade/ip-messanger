import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:ip_messanger/models/user_model.dart';
import 'package:ip_messanger/services/auth_service.dart';

class UserService {
  UserService._();

  static final firestore = FirebaseFirestore.instance;

  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!);
      } else {
        return null;
      }
    } catch (error) {
      print(error);
      throw Exception("Error getting the user data");
    }
  }

  static Future<UserModel?> getCurrentUser() async {
    final String? uid = AuthService.getUID();
    if (uid == null) {
      return null;
    }

    UserModel? currentUser = await getUser(uid);

    UserModel.currentUser = currentUser;

    return currentUser;
  }

  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final snap =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();
      return snap.docs.isEmpty;
    } catch (error) {
      throw Exception('Error while checking for username.');
    }
  }

  static Future<String> getMyIp() async {
    final response = await http.get(Uri.parse('https://api.ipify.org/'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      print('API Call failed while getting IP address: ' + response.toString());
      throw Exception('Failed to get IP address');
    }
  }
}
