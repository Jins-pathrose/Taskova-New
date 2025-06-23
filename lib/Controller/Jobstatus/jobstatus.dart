import 'package:flutter/material.dart';

class JobStatusProvider extends ChangeNotifier {
  String _status = 'pending';

  String get status => _status;

  set status(String newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  void reset() {
    _status = 'pending';
    notifyListeners();
  }
}