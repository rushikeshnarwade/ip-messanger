import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ip_messanger/models/interaction_model.dart';

class InteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentDeviceID;

  DocumentSnapshot? _lastVisible;
  static const int _pageSize = 20;

  InteractionService({required this.currentDeviceID}) {
    _setupOnlineStatus();
  }

  void _setupOnlineStatus() {
    // Update online status when app is active
    _firestore.collection('users').doc(currentDeviceID).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // Set up offline status callback for when app closes
    FirebaseFirestore.instance.doc('users/$currentDeviceID').set({
      '.sv': {
        'state': {
          'disconnect': {
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          },
        },
      },
    }, SetOptions(merge: true));
  }

  Stream<List<InteractionModel>> listenToInitialInteractions() {
    return _firestore
        .collection('interactions')
        .doc(currentDeviceID)
        .collection('peers')
        .orderBy('lastMessageTimestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            _lastVisible = snapshot.docs.last;
          }

          final interactions = <InteractionModel>[];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Fetch online status and connection info
            final userDoc =
                await _firestore
                    .collection('users')
                    .doc(data['peerDeviceID'])
                    .get();

            if (userDoc.exists) {
              data['isOnline'] = userDoc.data()?['isOnline'] ?? false;
              data['connectionInfo'] = userDoc.data()?['connectionInfo'];
            }

            interactions.add(InteractionModel.fromFirestore(data));
          }
          return interactions;
        });
  }

  Future<List<InteractionModel>> fetchMoreInteractions() async {
    if (_lastVisible == null) return [];

    final snapshot =
        await _firestore
            .collection('interactions')
            .doc(currentDeviceID)
            .collection('peers')
            .orderBy('lastMessageTimestamp', descending: true)
            .startAfterDocument(_lastVisible!)
            .limit(_pageSize)
            .get();

    if (snapshot.docs.isNotEmpty) {
      _lastVisible = snapshot.docs.last;
    }

    final interactions = <InteractionModel>[];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Fetch online status and connection info
      final userDoc =
          await _firestore.collection('users').doc(data['peerDeviceID']).get();

      if (userDoc.exists) {
        data['isOnline'] = userDoc.data()?['isOnline'] ?? false;
        data['connectionInfo'] = userDoc.data()?['connectionInfo'];
      }

      interactions.add(InteractionModel.fromFirestore(data));
    }
    return interactions;
  }

  Future<void> updateConnectionInfo(
    String peerId,
    Map<String, dynamic> connectionInfo,
  ) async {
    await _firestore.collection('users').doc(currentDeviceID).update({
      'connectionInfo': connectionInfo,
    });
  }

  void resetPagination() {
    _lastVisible = null;
  }

  Future<void> dispose() async {
    await _firestore.collection('users').doc(currentDeviceID).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
      'connectionInfo': null,
    });
  }
}
