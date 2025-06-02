import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ip_messanger/models/interaction_model.dart';
import 'package:ip_messanger/services/interaction_service.dart';

class InteractionList extends StatefulWidget {
  final Function(String) onUserTap;

  const InteractionList({required this.onUserTap, super.key});

  @override
  State<InteractionList> createState() => _InteractionListState();
}

class _InteractionListState extends State<InteractionList> {
  late final InteractionService _service;
  final ScrollController _scrollController = ScrollController();

  List<InteractionModel> _interactions = [];
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User must be logged in');
    }

    _service = InteractionService(currentDeviceID: currentUserId);
    _scrollController.addListener(_onScrollEnd);

    _service.listenToInitialInteractions().listen((data) {
      setState(() {
        _interactions = data;
      });
    });
  }

  void _onScrollEnd() async {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isFetchingMore) {
      setState(() => _isFetchingMore = true);
      final more = await _service.fetchMoreInteractions();
      setState(() {
        _interactions.addAll(more);
        _isFetchingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildInteractionTile(InteractionModel interaction) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: interaction.isOnline ? Colors.green : Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        interaction.peerUsername ??
            "${interaction.peerIP} (${interaction.peerDeviceID})",
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(interaction.lastMessage),
          if (interaction.connectionInfo != null)
            Text(
              'WebRTC: ${interaction.connectionInfo!['status'] ?? 'Not connected'}',
              style: TextStyle(
                fontSize: 12,
                color:
                    interaction.connectionInfo!['status'] == 'connected'
                        ? Colors.green
                        : Colors.grey,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTimestamp(interaction.lastMessageTimestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (interaction.unreadCount > 0)
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${interaction.unreadCount}',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: () => widget.onUserTap(interaction.peerDeviceID),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _interactions.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _interactions.length) {
          return _buildInteractionTile(_interactions[index]);
        } else {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
