import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_app.dart';

class UserProvider extends ChangeNotifier {
  String? _role;
  String? _uid;
  UserApp? _user;

  String? get role => _role;
  String? get uid => _uid;
  UserApp? get user => _user;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setUid(String uid) {
    _uid = uid;
    notifyListeners();
  }

  void clearUser() {
    _role = null;
    _uid = null;
    _user = null;
    notifyListeners();
  }

  Future<void> fetchUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      _user = UserApp.fromMap(uid, doc.data()!);
      _role = _user?.role;
      _uid = _user?.uid;
      notifyListeners();
    }
  }
}
