import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Document re-upload request shown when staff/admin flags an order in Firestore.
class ReuploadRequest {
  ReuploadRequest({
    required this.orderDocId,
    required this.orderId,
    required this.documentKey,
    required this.title,
    required this.subtitle,
    required this.message,
    this.passportIndex,
    this.requestIndex,
  });

  final String orderDocId;
  final String orderId;
  final String documentKey;
  final String title;
  final String subtitle;
  final String message;
  final int? passportIndex;
  final int? requestIndex;

  bool get isVehicleGrant =>
      documentKey == 'vehicle_grant' || documentKey == 'vehicleGrant';

  IconData get icon =>
      isVehicleGrant ? Icons.directions_car_outlined : Icons.badge_outlined;
}

List<ReuploadRequest> parseReuploadRequests(
  String orderDocId,
  Map<String, dynamic> data,
) {
  final orderId = (data['orderId'] ?? orderDocId).toString();
  final results = <ReuploadRequest>[];

  final rawList = data['reuploadRequests'];
  if (rawList is List) {
    for (var i = 0; i < rawList.length; i++) {
      final entry = rawList[i];
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      if (!_isActiveReupload(map)) continue;
      results.add(
        _requestFromMap(
          orderDocId: orderDocId,
          orderId: orderId,
          map: map,
          requestIndex: i,
        ),
      );
    }
  }

  if (results.isEmpty && _isActiveReupload(data)) {
    results.add(
      _requestFromOrder(orderDocId: orderDocId, orderId: orderId, data: data),
    );
  }

  return results;
}

bool _isActiveReupload(Map<String, dynamic> map) {
  if (map['completed'] == true || map['resolved'] == true) return false;
  return map['needsReupload'] == true || map['reuploadRequested'] == true;
}

ReuploadRequest _requestFromMap({
  required String orderDocId,
  required String orderId,
  required Map<String, dynamic> map,
  int? requestIndex,
}) {
  final docKey = _documentKeyFrom(map);
  final passportIndex = _passportIndexFrom(map);
  return ReuploadRequest(
    orderDocId: orderDocId,
    orderId: orderId,
    documentKey: docKey,
    title:
        (map['title'] ??
                map['documentTitle'] ??
                _defaultTitle(docKey, passportIndex))
            .toString(),
    subtitle:
        (map['subtitle'] ??
                map['documentSubtitle'] ??
                _defaultSubtitle(docKey, passportIndex))
            .toString(),
    message:
        (map['message'] ??
                map['reuploadMessage'] ??
                'Please resubmit new document')
            .toString(),
    passportIndex: passportIndex,
    requestIndex: requestIndex,
  );
}

ReuploadRequest _requestFromOrder({
  required String orderDocId,
  required String orderId,
  required Map<String, dynamic> data,
}) {
  final map = <String, dynamic>{
    'documentType': data['reuploadDocumentType'] ?? data['documentType'],
    'documentKey': data['reuploadDocumentKey'] ?? data['documentKey'],
    'title': data['reuploadTitle'] ?? data['documentTitle'],
    'subtitle': data['reuploadSubtitle'] ?? data['documentSubtitle'],
    'message': data['reuploadMessage'],
    'passportIndex': data['reuploadPassportIndex'] ?? data['passportIndex'],
  };
  return _requestFromMap(orderDocId: orderDocId, orderId: orderId, map: map);
}

String _documentKeyFrom(Map<String, dynamic> map) {
  final raw =
      (map['documentKey'] ??
              map['documentType'] ??
              map['reuploadDocumentType'] ??
              'vehicle_grant')
          .toString()
          .toLowerCase();
  if (raw.contains('passport') || raw.contains('identification')) {
    return 'passport';
  }
  if (raw.contains('vehicle') || raw.contains('grant')) {
    return 'vehicle_grant';
  }
  return raw;
}

int? _passportIndexFrom(Map<String, dynamic> map) {
  final value = map['passportIndex'] ?? map['reuploadPassportIndex'];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _defaultTitle(String docKey, int? passportIndex) {
  if (docKey == 'passport') {
    return 'Identification Card or Passport';
  }
  return 'Vehicle Registration';
}

String _defaultSubtitle(String docKey, int? passportIndex) {
  if (docKey == 'passport') {
    return passportIndex != null ? 'Passenger $passportIndex' : 'Passport';
  }
  return 'Grant/VOC';
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color _navy = Color(0xFF1D3F70);
  static const Color _pageBg = Color(0xFFF0F4F8);
  static const int _maxFileBytes = 10 * 1024 * 1024;

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, File> _pendingFiles = {};
  final Map<String, bool> _uploadingKeys = {};

  String _uploadKey(ReuploadRequest request) =>
      '${request.orderDocId}_${request.documentKey}_${request.passportIndex ?? 0}_${request.requestIndex ?? -1}';

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _navy,
      ),
    );
  }

  Future<void> _pickFile(ReuploadRequest request) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_outlined, color: _navy),
                  title: const Text('Photo (JPG or PNG)'),
                  onTap: () => Navigator.pop(ctx, 'image'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: _navy,
                  ),
                  title: const Text('PDF document'),
                  onTap: () => Navigator.pop(ctx, 'pdf'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    File? file;
    if (choice == 'image') {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) file = File(picked.path);
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: false,
      );
      if (result != null && result.files.single.path != null) {
        file = File(result.files.single.path!);
      }
    }

    if (file == null || !mounted) return;
    final pickedFile = file;

    final ext = p.extension(pickedFile.path).toLowerCase();
    if (choice == 'image' && ext != '.jpg' && ext != '.jpeg' && ext != '.png') {
      _showSnack('Please choose a JPG or PNG image', isError: true);
      return;
    }
    if (choice == 'pdf' && ext != '.pdf') {
      _showSnack('Please choose a PDF file', isError: true);
      return;
    }

    final size = await pickedFile.length();
    if (size > _maxFileBytes) {
      _showSnack('File must be 10 MB or smaller', isError: true);
      return;
    }

    setState(() => _pendingFiles[_uploadKey(request)] = pickedFile);
  }

  Future<void> _confirmUpload(ReuploadRequest request) async {
    final key = _uploadKey(request);
    final file = _pendingFiles[key];
    if (file == null) {
      _showSnack('Please upload a document first', isError: true);
      return;
    }

    setState(() => _uploadingKeys[key] = true);
    try {
      await _submitReupload(request, file);
      if (!mounted) return;
      setState(() {
        _pendingFiles.remove(key);
        _uploadingKeys.remove(key);
      });
      _showSnack('Document submitted successfully');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _uploadingKeys.remove(key));
        _showSnack('Upload failed. Please try again.', isError: true);
      }
    }
  }

  Future<void> _submitReupload(ReuploadRequest request, File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ext = p.extension(file.path).toLowerCase();
    final storageExt = ext == '.jpeg' ? '.jpg' : ext;

    late final String storagePath;
    if (request.isVehicleGrant) {
      storagePath = 'orders/${request.orderId}/vehicle_grant$storageExt';
    } else {
      final index = request.passportIndex ?? 1;
      storagePath = 'orders/${request.orderId}/passport_$index$storageExt';
    }

    final ref = FirebaseStorage.instance.ref().child(storagePath);
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    final docRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(request.orderDocId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Order not found');

      final data = Map<String, dynamic>.from(snap.data()!);
      final documents = Map<String, dynamic>.from(
        (data['documents'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      if (request.isVehicleGrant) {
        documents['vehicleGrantUrl'] = downloadUrl;
      } else {
        final urls = List<String>.from(
          (documents['passportUrls'] as List?)?.map((e) => e.toString()) ?? [],
        );
        final index = (request.passportIndex ?? 1) - 1;
        while (urls.length <= index) {
          urls.add('');
        }
        urls[index] = downloadUrl;
        documents['passportUrls'] = urls;
      }

      final updates = <String, dynamic>{
        'documents': documents,
        'reuploadSubmittedAt': FieldValue.serverTimestamp(),
        'reuploadConfirmedAt': FieldValue.serverTimestamp(),
      };

      if (request.requestIndex != null) {
        final list = List<dynamic>.from(
          data['reuploadRequests'] as List? ?? [],
        );
        if (request.requestIndex! < list.length) {
          final item = Map<String, dynamic>.from(
            list[request.requestIndex!] as Map,
          );
          item['needsReupload'] = false;
          item['reuploadRequested'] = false;
          item['completed'] = true;
          item['resolvedAt'] = FieldValue.serverTimestamp();
          list[request.requestIndex!] = item;
          updates['reuploadRequests'] = list;

          final hasPending = list.any((e) {
            if (e is! Map) return false;
            final m = Map<String, dynamic>.from(e);
            return _isActiveReupload(m);
          });
          updates['needsReupload'] = hasPending;
          updates['reuploadRequested'] = hasPending;
        }
      } else {
        updates['needsReupload'] = false;
        updates['reuploadRequested'] = false;
      }

      tx.update(docRef, updates);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: _navy),
        title: const Text(
          'Notification',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to view notifications.',
                style: TextStyle(fontSize: 16, color: _navy),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _navy),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load notifications.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                }

                final notifications = <ReuploadRequest>[];
                for (final doc in snapshot.data?.docs ?? []) {
                  final data = doc.data() as Map<String, dynamic>;
                  notifications.addAll(parseReuploadRequests(doc.id, data));
                }

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No new notifications',
                      style: TextStyle(
                        fontSize: 16,
                        color: _navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final request = notifications[index];
                    final key = _uploadKey(request);
                    return _NotificationCard(
                      request: request,
                      pendingFile: _pendingFiles[key],
                      isUploading: _uploadingKeys[key] == true,
                      onUploadTap: () => _pickFile(request),
                      onConfirmTap: () => _confirmUpload(request),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.request,
    required this.pendingFile,
    required this.isUploading,
    required this.onUploadTap,
    required this.onConfirmTap,
  });

  final ReuploadRequest request;
  final File? pendingFile;
  final bool isUploading;
  final VoidCallback onUploadTap;
  final VoidCallback onConfirmTap;

  bool get _hasPendingFile => pendingFile != null;
  bool get _isPdf =>
      pendingFile != null &&
      p.extension(pendingFile!.path).toLowerCase() == '.pdf';

  static const Color _navy = Color(0xFF1D3F70);
  static const Color _uploadBg = Color(0xFFEBF2F7);
  static const Color _iconTileBg = Color(0xFFD6E6F2);
  static const Color _requiredRed = Color(0xFFE57373);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request.message}:',
            style: const TextStyle(
              fontSize: 13,
              color: _navy,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.orderId,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconTileBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(request.icon, color: _navy, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _requiredRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: isUploading ? null : onUploadTap,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFF90A4BE),
                strokeWidth: 1.5,
                dashWidth: 6,
                dashSpace: 4,
                radius: 14,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _uploadBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _navy,
                        ),
                      )
                    else if (_hasPendingFile && !_isPdf)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          pendingFile!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_hasPendingFile && _isPdf)
                      Column(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: _navy,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.basename(pendingFile!.path),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _navy,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: _navy,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to upload',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PDF, JPG OR PNG (MAX 10MB)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (_hasPendingFile && !isUploading) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Tap again to change file',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_hasPendingFile) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: isUploading ? null : onConfirmTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _navy.withValues(alpha: 0.5),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}
