import 'package:flutter/foundation.dart';

class TransactionRefreshController extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
