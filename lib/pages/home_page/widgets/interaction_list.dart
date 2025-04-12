import 'package:flutter/material.dart';
import 'package:ip_messanger/models/interaction_model.dart';
import 'package:ip_messanger/services/interaction_service.dart';

class InteractionList extends StatefulWidget {
  final String currentDeviceID;

  const InteractionList({required this.currentDeviceID, super.key});

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
    _service = InteractionService(currentDeviceID: widget.currentDeviceID);

    _scrollController.addListener(_onScrollEnd);

    _service.listenToInitialInteractions().listen((data) {
      setState(() {
        _interactions = data;
      });
    });
  }

  void _onScrollEnd() async {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !_isFetchingMore) {
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
      title: Text(interaction.peerUsername ?? "${interaction.peerIP} (${interaction.peerDeviceID})"),
      subtitle: Text(interaction.lastMessage),
      trailing: Text(
        interaction.lastMessageTimestamp.toDate().toLocal().toString(),
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        // Navigate to chat screen
      },
    );
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
