import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/report_model.dart';
import 'package:memory_pins_app/services/report_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportBlockDialog extends StatefulWidget {
  final String reportedUserId;
  final String? reportedPinId;
  final String? reportedTapuId;
  final String reportedUserName;

  const ReportBlockDialog({
    Key? key,
    required this.reportedUserId,
    this.reportedPinId,
    this.reportedTapuId,
    required this.reportedUserName,
  }) : super(key: key);

  @override
  State<ReportBlockDialog> createState() => _ReportBlockDialogState();
}

class _ReportBlockDialogState extends State<ReportBlockDialog> {
  final ReportService _reportService = ReportService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is the content creator
  bool get _isOwnContent {
    final currentUserId = _auth.currentUser?.uid;
    return currentUserId == widget.reportedUserId;
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReportDialog(
        reportedUserId: widget.reportedUserId,
        reportedPinId: widget.reportedPinId,
        reportedTapuId: widget.reportedTapuId,
        reportedUserName: widget.reportedUserName,
        reportService: _reportService,
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BlockDialog(
        reportedUserId: widget.reportedUserId,
        reportedUserName: widget.reportedUserName,
        reportService: _reportService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show report/block options for own content
    if (_isOwnContent) {
      return AlertDialog(
        backgroundColor: const Color(0xFF15212F),
        title: const Text(
          'No Actions Available',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'You cannot report or block your own content.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF15212F),
      title: Text(
        'Options for ${widget.reportedUserName}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag, color: Colors.orange),
            title: const Text(
              'Report User',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Report inappropriate behavior or content',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text(
              'Block User',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Hide all content from this user',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              _showBlockDialog();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String reportedUserId;
  final String? reportedPinId;
  final String? reportedTapuId;
  final String reportedUserName;
  final ReportService reportService;

  const _ReportDialog({
    required this.reportedUserId,
    this.reportedPinId,
    this.reportedTapuId,
    required this.reportedUserName,
    required this.reportService,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (selectedReason == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      if (widget.reportedPinId != null) {
        success = await widget.reportService.reportPin(
          reportedUserId: widget.reportedUserId,
          reportedPinId: widget.reportedPinId!,
          reason: selectedReason!,
          description: _descriptionController.text.trim(),
        );
      } else if (widget.reportedTapuId != null) {
        success = await widget.reportService.reportTapu(
          reportedUserId: widget.reportedUserId,
          reportedTapuId: widget.reportedTapuId!,
          reason: selectedReason!,
          description: _descriptionController.text.trim(),
        );
      } else {
        success = await widget.reportService.reportUser(
          reportedUserId: widget.reportedUserId,
          reason: selectedReason!,
          description: _descriptionController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pop(context); // Close report dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF15212F),
      title: Text(
        'Report ${widget.reportedUserName}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting this?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...ReportReasons.contentReasons
                .map((reason) => RadioListTile<String>(
                      title: Text(
                        reason,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                      activeColor: const Color(0xFFEBA145),
                    )),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFEBA145)),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed:
              (selectedReason == null || _isLoading) ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEBA145),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Submit Report',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

class _BlockDialog extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;
  final ReportService reportService;

  const _BlockDialog({
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reportService,
  });

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  bool _isLoading = false;

  Future<void> _submitBlock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.reportService.blockUser(
        blockedUserId: widget.reportedUserId,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close block dialog
      Navigator.pop(context); // Close main dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.reportedUserName} has been blocked'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to block user. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF15212F),
      title: Text(
        'Block ${widget.reportedUserName}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Are you sure you want to block this user?',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'You won\'t see their content anymore, and they won\'t be able to see yours.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitBlock,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Block User',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
