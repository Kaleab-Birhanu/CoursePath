import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BulkActionsScreen extends StatefulWidget {
  const BulkActionsScreen({super.key});

  @override
  State<BulkActionsScreen> createState() => _BulkActionsScreenState();
}

class _BulkActionsScreenState extends State<BulkActionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedAddRequests = {};
  final Set<String> _selectedDropRequests = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bulkApproveAdd() async {
    if (_selectedAddRequests.isEmpty) return;

    final confirm = await _showConfirmDialog(
      'Approve ${_selectedAddRequests.length} add requests?',
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var id in _selectedAddRequests) {
      final ref = FirebaseFirestore.instance
          .collection('requests')
          .doc('add')
          .collection('items')
          .doc(id);
      batch.update(ref, {'status': 'approved', 'approved': true});
    }

    await batch.commit();
    setState(() => _selectedAddRequests.clear());

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Requests approved')));
    }
  }

  Future<void> _bulkDenyAdd() async {
    if (_selectedAddRequests.isEmpty) return;

    final confirm = await _showConfirmDialog(
      'Deny ${_selectedAddRequests.length} add requests?',
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var id in _selectedAddRequests) {
      final ref = FirebaseFirestore.instance
          .collection('requests')
          .doc('add')
          .collection('items')
          .doc(id);
      batch.update(ref, {'status': 'denied', 'approved': false});
    }

    await batch.commit();
    setState(() => _selectedAddRequests.clear());

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Requests denied')));
    }
  }

  Future<void> _bulkApproveDrop() async {
    if (_selectedDropRequests.isEmpty) return;

    final confirm = await _showConfirmDialog(
      'Approve ${_selectedDropRequests.length} drop requests?',
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var id in _selectedDropRequests) {
      final ref = FirebaseFirestore.instance
          .collection('requests')
          .doc('drop')
          .collection('items')
          .doc(id);
      batch.update(ref, {'status': 'approved', 'approved': true});
    }

    await batch.commit();
    setState(() => _selectedDropRequests.clear());

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Drop requests approved')));
    }
  }

  Future<void> _bulkDenyDrop() async {
    if (_selectedDropRequests.isEmpty) return;

    final confirm = await _showConfirmDialog(
      'Deny ${_selectedDropRequests.length} drop requests?',
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var id in _selectedDropRequests) {
      final ref = FirebaseFirestore.instance
          .collection('requests')
          .doc('drop')
          .collection('items')
          .doc(id);
      batch.update(ref, {'status': 'denied', 'approved': false});
    }

    await batch.commit();
    setState(() => _selectedDropRequests.clear());

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Drop requests denied')));
    }
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Actions'),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Add Requests'),
            Tab(text: 'Drop Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAddRequestsTab(), _buildDropRequestsTab()],
      ),
      bottomNavigationBar: _tabController.index == 0
          ? _buildAddActionsBar()
          : _buildDropActionsBar(),
    );
  }

  Widget _buildAddRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .doc('add')
          .collection('items')
          .where('status', isNull: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending add requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isSelected = _selectedAddRequests.contains(doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedAddRequests.add(doc.id);
                    } else {
                      _selectedAddRequests.remove(doc.id);
                    }
                  });
                },
                title: Text(
                  data['courseCode'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['courseName'] ?? 'Unknown Course'),
                    Text('Student: ${data['studentName'] ?? 'Unknown'}'),
                    Text('Section: ${data['section'] ?? 'N/A'}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .doc('drop')
          .collection('items')
          .where('status', isNull: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending drop requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isSelected = _selectedDropRequests.contains(doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedDropRequests.add(doc.id);
                    } else {
                      _selectedDropRequests.remove(doc.id);
                    }
                  });
                },
                title: Text(
                  data['courseCode'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['courseName'] ?? 'Unknown Course'),
                    Text('Student: ${data['studentName'] ?? 'Unknown'}'),
                    Text('Reason: ${data['reason'] ?? 'Not specified'}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddActionsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedAddRequests.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedAddRequests.isEmpty ? null : _bulkDenyAdd,
            icon: const Icon(Icons.close),
            label: const Text('Deny'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedAddRequests.isEmpty ? null : _bulkApproveAdd,
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropActionsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedDropRequests.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedDropRequests.isEmpty ? null : _bulkDenyDrop,
            icon: const Icon(Icons.close),
            label: const Text('Deny'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedDropRequests.isEmpty ? null : _bulkApproveDrop,
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
