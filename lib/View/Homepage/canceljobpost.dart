import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoCancelJobPage extends StatefulWidget {
  final int jobPost; // Unique identifier for the job request
  final String jobRequestId;
  final Function(String reason) onJobCancelled;

  const CupertinoCancelJobPage({
    super.key,
    required this.jobRequestId,
    required this.jobPost,
    required this.onJobCancelled,
  });

  @override
  State<CupertinoCancelJobPage> createState() => _CupertinoCancelJobPageState();
}

class _CupertinoCancelJobPageState extends State<CupertinoCancelJobPage> {
  final TextEditingController _otherReasonController = TextEditingController();
  String? _selectedReason;

  final List<String> _reasons = [
    'Found another job',
    'Change of plans',
    'Pay not suitable',
    'Job too far',
    'Not interested anymore',
    'Other',
  ];

  void _submitCancellation() {
    if (_selectedReason == null) {
      _showAlert('Please select a reason to cancel.');
      return;
    }

    if (_selectedReason == 'Other' && _otherReasonController.text.trim().isEmpty) {
      _showAlert('Please provide your reason.');
      return;
    }

    String finalReason = _selectedReason == 'Other'
        ? _otherReasonController.text.trim()
        : _selectedReason!;

    Navigator.pop(context); // Close the modal
    widget.onJobCancelled(finalReason); // Pass reason to parent
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Cancel Application'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            children: [
              const Text(
                'Why do you want to cancel this job application?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ..._reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: _selectedReason == reason
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: _selectedReason == reason
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedReason == 'Other') ...[
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: _otherReasonController,
                  placeholder: 'Please specify your reason',
                  maxLines: 3,
                  padding: const EdgeInsets.all(12),
                ),
              ],
              const SizedBox(height: 30),
              CupertinoButton.filled(
                child: const Text('Cancel Application'),
                onPressed: _submitCancellation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
