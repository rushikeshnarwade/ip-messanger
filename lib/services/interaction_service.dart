import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ip_messanger/models/interaction_model.dart';

class InteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentDeviceID;

  DocumentSnapshot? _lastVisible;
  static const int _pageSize = 20;

  InteractionService({required this.currentDeviceID});

  Stream<List<InteractionModel>> listenToInitialInteractions() {
    return _firestore
        .collection('interactions')
        .doc(currentDeviceID)
        .collection('peers')
        .orderBy('lastMessageTimestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _lastVisible = snapshot.docs.last;
          }
          return snapshot.docs.map((doc) => InteractionModel.fromFirestore(doc.data())).toList();
        });
  }

  Future<List<InteractionModel>> fetchMoreInteractions() async {
    if (_lastVisible == null) return [];

    final snapshot = await _firestore
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

    return snapshot.docs.map((doc) => InteractionModel.fromFirestore(doc.data())).toList();
  }

  void resetPagination() {
    _lastVisible = null;
  }
}
