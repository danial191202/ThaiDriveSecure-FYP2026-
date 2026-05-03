import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String _formatStatusDisplay(String? orderStatus) {
  final String status = orderStatus ?? '';
  final String formattedStatus = status.isNotEmpty
      ? status[0].toUpperCase() + status.substring(1).toLowerCase()
      : '';
  return formattedStatus;
}

/// Application tracking — same `orders` query as Application History; UI only.
class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  static const Color _navy = Color(0xFF1D3F70);
  static const Color _pageBg = Color(0xFFEAF3F8);
  static const Color _iconBg = Color(0xFFD4E8F7);
  static const Color _tealAccent = Color(0xFF36A9A6);
  static const Color _completedGreen = Color(0xFF2E7D32);
  static const Color _completedCardBg = Color(0xFFE8F5E9);
  static const Color _completedIconBg = Color(0xFFB2DFDB);
  static const Color _statusPillGreenBg = Color(0xFFC8E6C9);
  static const Color _statusPillGreenText = Color(0xFF1B5E20);

  static const List<String> _tabs = [
    'All',
    'Applied',
    'Pending',
    'Approved',
    'Completed',
  ];

  String selectedTab = 'All';

  /// Local-only hide after Done (does not change Firestore).
  final Set<String> _dismissedOrderIds = {};

  /// Same mapping as [HistoryPage._mapFirestoreStatusToTab].
  String _mapFirestoreStatusToTab(String? status) {
    if (status == null) return 'Pending';

    switch (status.toLowerCase()) {
      case 'order pending':
      case 'pending':
      case 'pending verification':
      case 'payment submitted':
        return 'Pending';

      case 'already pickup':
      case 'completed':
      case 'verified':
        return 'Completed';

      default:
        return 'Pending';
    }
  }

  /// Label shown on cards — matches Application History.
  String _historyDisplayStatus(Map<String, dynamic> order) =>
      _mapFirestoreStatusToTab(order['status']?.toString());

  /// Which top tab this order belongs to (filter + card tap).
  String _trackingTabForOrder(Map<String, dynamic> order) {
    if (_historyDisplayStatus(order) == 'Completed') return 'Completed';
    final raw = (order['status'] ?? '').toString().trim().toLowerCase();
    if (raw.contains('approv')) return 'Approved';
    if (raw.contains('applied') || raw == 'submitted') return 'Applied';
    return 'Pending';
  }

  /// Timeline step index 0..3 — keeps prior progression; Pending from history → step 1.
  int _timelineIndex(Map<String, dynamic> order) {
    if (_historyDisplayStatus(order) == 'Completed') return 3;
    switch (_trackingTabForOrder(order)) {
      case 'Applied':
        return 0;
      case 'Approved':
        return 2;
      case 'Pending':
      default:
        return 1;
    }
  }

  DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    try {
      final dynamic d = raw.toDate();
      if (d is DateTime) return d;
    } catch (_) {}
    return null;
  }

  String _formatDateTimeLine(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${h12.toString()}:$m $period, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatExpectedDelivery(Map<String, dynamic> order) {
    final base =
        _toDate(order['statusUpdatedAt']) ?? _toDate(order['createdAt']);
    if (base == null) return 'Expected delivery: —';
    final exp = base.add(const Duration(days: 1));
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Expected delivery: ${exp.day} ${months[exp.month - 1]} ${exp.year}';
  }

  List<Map<String, dynamic>> _ordersFromSnapshot(QuerySnapshot snap) {
    final list = snap.docs.map((doc) {
      final m = Map<String, dynamic>.from(doc.data()! as Map<String, dynamic>);
      m['orderId'] ??= doc.id;
      return m;
    }).toList()
      ..sort((a, b) {
        final ac = _toDate(a['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bc = _toDate(b['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bc.compareTo(ac);
      });
    return list
        .where((o) => !_dismissedOrderIds.contains(o['orderId']?.toString()))
        .toList();
  }

  List<Map<String, dynamic>> _visibleOrders(List<Map<String, dynamic>> all) {
    if (selectedTab == 'All') return List.from(all);
    final want = selectedTab.trim().toLowerCase();
    return all.where((o) {
      final s = (o['status'] ?? '').toString().trim().toLowerCase();
      return s == want;
    }).toList();
  }

  /// Maps raw [order['status']] to a dropdown value (canonical casing from [_tabs]).
  String _dropdownValueForOrderStatus(dynamic raw) {
    final r = (raw ?? '').toString().trim().toLowerCase();
    if (r.isEmpty) return 'All';
    for (final t in _tabs) {
      if (t.toLowerCase() == r) return t;
    }
    return 'All';
  }

  void _onDone(Map<String, dynamic> order) {
    final id = order['orderId']?.toString();
    if (id == null) return;
    setState(() => _dismissedOrderIds.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Application Tracking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to view application tracking.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatusDropdown(),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading orders:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No orders found.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      final all = _ordersFromSnapshot(snapshot.data!);
                      final visible = _visibleOrders(all);

                      if (visible.isEmpty) {
                        return Center(
                          child: Text(
                            selectedTab == 'All'
                                ? 'No orders to display.'
                                : 'No orders in "$selectedTab".',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 16),
                          ),
                        );
                      }

                      return selectedTab == 'All'
                          ? _buildAllList(visible)
                          : _buildFilteredDetail(visible);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedTab,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _tabs
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(_formatStatusDisplay(e)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedTab = value);
          },
        ),
      ),
    );
  }

  Widget _buildAllList(List<Map<String, dynamic>> visible) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final order = visible[i];
        return _OrderListCard(
          order: order,
          onTap: () {
            setState(() => selectedTab = _dropdownValueForOrderStatus(order['status']));
          },
        );
      },
    );
  }

  Widget _buildFilteredDetail(List<Map<String, dynamic>> visible) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, i) {
        final order = visible[i];
        final displayStatus = _historyDisplayStatus(order);
        final isCompleted = displayStatus == 'Completed';
        final ti = _timelineIndex(order);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MergedTrackingCard(
              order: order,
              displayStatus: displayStatus,
              isCompleted: isCompleted,
              timelineIndex: ti,
              navy: _navy,
              iconBg: _iconBg,
              tealAccent: _tealAccent,
              completedCardBg: _completedCardBg,
              completedIconBg: _completedIconBg,
              completedGreen: _completedGreen,
              statusPillBg: isCompleted ? _statusPillGreenBg : _iconBg,
              statusPillFg:
                  isCompleted ? _statusPillGreenText : _navy,
              summaryDescription: isCompleted
                  ? "You're all set! Your application is approved and ready to go."
                  : "We've got your application! It's now being reviewed—hang tight while we process it.",
              toDate: _toDate,
              formatDateTimeLine: _formatDateTimeLine,
              formatExpectedDelivery: _formatExpectedDelivery,
            ),
            if (isCompleted) ...[
              const SizedBox(height: 20),
              _DoneButton(onPressed: () => _onDone(order)),
            ],
          ],
        );
      },
    );
  }
}

class _OrderListCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderListCard({
    required this.order,
    required this.onTap,
  });

  static const Color _navy = Color(0xFF1D3F70);
  static const Color _iconBg = Color(0xFFD4E8F7);

  @override
  Widget build(BuildContext context) {
    final orderId = order['orderId']?.toString() ?? '—';
    final formattedStatus =
        _formatStatusDisplay(order['status']?.toString());
    const desc =
        "We've got your application! It's now being reviewed—hang tight while we process it.";

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: _navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formattedStatus.isEmpty ? '—' : formattedStatus,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Order $orderId',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: _navy,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      desc,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF7D8896),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single card: header (STATUS + status + order id), car + description, timeline.
class _MergedTrackingCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String displayStatus;
  final bool isCompleted;
  final int timelineIndex;
  final Color navy;
  final Color iconBg;
  final Color tealAccent;
  final Color completedCardBg;
  final Color completedIconBg;
  final Color completedGreen;
  final Color statusPillBg;
  final Color statusPillFg;
  final String summaryDescription;
  final DateTime? Function(dynamic) toDate;
  final String Function(DateTime?) formatDateTimeLine;
  final String Function(Map<String, dynamic>) formatExpectedDelivery;

  const _MergedTrackingCard({
    required this.order,
    required this.displayStatus,
    required this.isCompleted,
    required this.timelineIndex,
    required this.navy,
    required this.iconBg,
    required this.tealAccent,
    required this.completedCardBg,
    required this.completedIconBg,
    required this.completedGreen,
    required this.statusPillBg,
    required this.statusPillFg,
    required this.summaryDescription,
    required this.toDate,
    required this.formatDateTimeLine,
    required this.formatExpectedDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['orderId']?.toString() ?? '—';
    final String status = (order['status'] ?? '').toString();
    final formattedStatus = status.isNotEmpty
        ? _formatStatusDisplay(status)
        : _formatStatusDisplay(displayStatus);

    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? completedCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted ? statusPillBg : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: statusPillFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        formattedStatus.isEmpty ? '—' : formattedStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCompleted ? completedGreen : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Order $orderId',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isCompleted ? completedIconBg : iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: isCompleted ? Colors.white : navy,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  summaryDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF7D8896),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TimelineBlock(
            order: order,
            navy: navy,
            tealAccent: tealAccent,
            statusIndex: timelineIndex,
            toDate: toDate,
            formatDateTimeLine: formatDateTimeLine,
            formatExpectedDelivery: formatExpectedDelivery,
            embedded: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color navy;
  final Color tealAccent;
  final int statusIndex;
  final DateTime? Function(dynamic) toDate;
  final String Function(DateTime?) formatDateTimeLine;
  final String Function(Map<String, dynamic>) formatExpectedDelivery;
  final bool embedded;

  const _TimelineBlock({
    required this.order,
    required this.navy,
    required this.tealAccent,
    required this.statusIndex,
    required this.toDate,
    required this.formatDateTimeLine,
    required this.formatExpectedDelivery,
    this.embedded = false,
  });

  static const double _gutterW = 40;
  static const double _lineX = 19;
  static const double _rowH = 96;
  static const double _iconD = 32;
  static const double _halfLine =
      _rowH / 2 - _iconD / 2; // line from row edge to icon center

  @override
  Widget build(BuildContext context) {
    final created = toDate(order['createdAt']);
    final updated = toDate(order['statusUpdatedAt']);
    final ci = statusIndex.clamp(0, 3);

    const steps = [
      _StepDef(
        keyName: 'Applied',
        description: 'We have received your application and initial payment.',
        completedIcon: Icons.check,
        currentIcon: Icons.check,
        futureIcon: Icons.check,
      ),
      _StepDef(
        keyName: 'Pending',
        description:
            'Our staffs are reviewing your documents for final approval',
        completedIcon: Icons.sync,
        currentIcon: Icons.sync,
        futureIcon: Icons.sync,
      ),
      _StepDef(
        keyName: 'Approved',
        description: 'Your insurance application is being approved.',
        completedIcon: Icons.local_shipping,
        currentIcon: Icons.local_shipping,
        futureIcon: Icons.local_shipping,
      ),
      _StepDef(
        keyName: 'Completed',
        description:
            'Insurance active. Thank you for choosing ThaiDriveSecure!',
        completedIcon: Icons.verified,
        currentIcon: Icons.verified,
        futureIcon: Icons.verified,
      ),
    ];

    final timelineColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (i) {
          final def = steps[i];
          final isPast = ci > i;
          final isCurrent = ci == i;
          final isFuture = ci < i;
          final bool allDone = ci == 3;

          final bool filledBlue = allDone || isPast || isCurrent;

          String? extraLine;
          Color? extraColor;
          if (i == 0) {
            extraLine = formatDateTimeLine(created);
            extraColor =
                filledBlue && !isFuture ? navy : const Color(0xFFBDC5D2);
          } else if (i == 1) {
            if (ci >= 1) {
              extraLine = formatDateTimeLine(updated ?? created);
              extraColor =
                  filledBlue && !isFuture ? navy : const Color(0xFFBDC5D2);
            }
          } else if (i == 2) {
            if (ci >= 2) {
              extraLine = formatExpectedDelivery(order);
              extraColor =
                  filledBlue && !isFuture ? navy : const Color(0xFFBDC5D2);
            }
          }

          final titleStyle = TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isFuture ? const Color(0xFFBDC5D2) : Colors.black87,
          );
          final descStyle = TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isFuture
                ? const Color(0xFFD0D5DC)
                : const Color(0xFF7D8896),
          );

          final IconData iconData = isFuture
              ? def.futureIcon
              : isCurrent
                  ? def.currentIcon
                  : def.completedIcon;

          final Color lineBelow =
              i < 3 && ci > i ? navy : const Color(0xFFE0E4EA);

          return SizedBox(
            height: _rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _gutterW,
                  height: _rowH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (i > 0)
                        Positioned(
                          left: _lineX,
                          top: 0,
                          width: 2,
                          height: _halfLine,
                          child: Container(
                            color: ci >= i
                                ? navy
                                : const Color(0xFFE0E4EA),
                          ),
                        ),
                      if (i < 3)
                        Positioned(
                          left: _lineX,
                          top: _rowH / 2 + _iconD / 2,
                          width: 2,
                          height: _halfLine,
                          child: Container(color: lineBelow),
                        ),
                      _StepDot(
                        navy: navy,
                        isFuture: isFuture,
                        icon: iconData,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _formatStatusDisplay(def.keyName),
                                style: titleStyle,
                              ),
                            ),
                            if (isCurrent && !isFuture) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tealAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(def.description, style: descStyle),
                        if (extraLine != null && extraLine.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            extraLine,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: extraColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
    );

    if (embedded) {
      return timelineColumn;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: timelineColumn,
    );
  }
}

class _StepDef {
  final String keyName;
  final String description;
  final IconData completedIcon;
  final IconData currentIcon;
  final IconData futureIcon;

  const _StepDef({
    required this.keyName,
    required this.description,
    required this.completedIcon,
    required this.currentIcon,
    required this.futureIcon,
  });
}

class _StepDot extends StatelessWidget {
  final Color navy;
  final bool isFuture;
  final IconData icon;

  const _StepDot({
    required this.navy,
    required this.isFuture,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isFuture) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD0D5DC), width: 2),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFBDC5D2)),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: navy,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DoneButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D3F70),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
