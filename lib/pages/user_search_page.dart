import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ip_messanger/models/user_model.dart';
import 'package:ip_messanger/services/webrtc_chat_screen.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({Key? key}) : super(key: key);

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isGreaterThanOrEqualTo: query)
              .where('username', isLessThan: query + 'z')
              .get();

      final users =
          querySnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc.data()))
              .where((user) => user.id != currentUser.uid)
              .toList();

      setState(() => _searchResults = users);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startChat(BuildContext context, UserModel user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WebRTCChatScreen(
              remotePeerId: user.id,
              currentUserId: currentUser.uid,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                user.isOnline ? Colors.green : Colors.grey,
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user.username),
                          subtitle: Text(user.email),
                          trailing: Icon(
                            Icons.circle,
                            size: 12,
                            color: user.isOnline ? Colors.green : Colors.grey,
                          ),
                          onTap: () => _startChat(context, user),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
