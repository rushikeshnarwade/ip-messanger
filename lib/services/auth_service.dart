import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ip_messanger/models/user_model.dart';
import 'package:ip_messanger/services/user_service.dart';

class AuthService {
  AuthService._();
  static final auth = FirebaseAuth.instance;

  static String? getUID() {
    return auth.currentUser?.uid;
  }

  static Future<void> login(String email, String password) async {
    try {
      final userCreds = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCreds.user != null) {
        await UserService.getCurrentUser();
      }
    } on FirebaseAuthException catch (error) {
      print(error);
      throw Exception("auth-error");
    } catch (error) {
      print(error);
      throw Exception("Something bad happened");
    }
  }

  static Future<void> logout() async {
    await auth.signOut();
  }

  static Future<void> signup(
    String username,
    String email,
    String password,
  ) async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (error) {
      print(error);
      throw Exception('Error while creating the account');
    }

    try {
      final user = UserModel(
        username,
        await UserService.getMyIp(),
        DateTime.now(),
        getUID()!,
        email,
      );

      final firestore = FirebaseFirestore.instance;

      final usernameRef = firestore.collection('usernames').doc(user.username);
      final userRef = firestore.collection('users').doc(user.uid);

      await firestore.runTransaction((transaction) async {
        final usernameSnapshot = await transaction.get(usernameRef);

        if (usernameSnapshot.exists) {
          throw Exception("Username already taken");
        }

        transaction.set(usernameRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(userRef, user.toJSON());
      });
    } catch (error) {
      print(error);

      throw Exception('Not able to create the user account.');
    }
  }
}
