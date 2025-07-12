import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static void show(String message) {
    Fluttertoast.showToast(msg: message, gravity: ToastGravity.TOP);
  }
}
