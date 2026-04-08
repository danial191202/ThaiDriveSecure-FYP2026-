import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate next order ID like TDS-001
  Future<String> generateOrderId() async {
    final counterRef = _firestore.collection('counters').doc('orders');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int newCount = 1;
      if (snapshot.exists) {
        newCount = (snapshot.data()?['count'] ?? 0) + 1;
      }

      transaction.set(counterRef, {'count': newCount});

      return 'TDS-${newCount.toString().padLeft(3, '0')}';
    });
  }

  /// Create order in Firestore
  Future<void> createOrder({
    required String packageName,
    required String vehicleType,
    required String amount,
    required String deliveryMethod,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final orderId = await generateOrderId();

    await _firestore.collection('orders').add({
      'orderId': orderId,
      'userId': user.uid,
      'packageName': packageName,
      'vehicleType': vehicleType,
      'amount': amount,
      'deliveryMethod': deliveryMethod,
      'status': 'Order Pending',
      'createdAt': FieldValue.serverTimestamp(),
      'statusHistory': [
        {
          'step': 'Order Pending',
          'completed': true,
          'time': DateTime.now().toIso8601String(),
        },
        {
          'step': 'Order Received',
          'completed': false,
        },
        {
          'step': 'In Process',
          'completed': false,
        },
        {
          'step': 'On The Way',
          'completed': false,
        },
        {
          'step': 'Already Pickup',
          'completed': false,
        },
      ],
    });
  }

  /// Realtime stream of current user's orders
  Stream<QuerySnapshot> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get one order realtime
  Stream<DocumentSnapshot> getOrderById(String docId) {
    return _firestore.collection('orders').doc(docId).snapshots();
  }
}