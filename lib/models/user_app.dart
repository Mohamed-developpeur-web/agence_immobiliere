class UserApp {
  final String uid;
  final String email;
  final String pseudo;
  final String role;

  UserApp({
    required this.uid,
    required this.email,
    required this.pseudo,
    required this.role,
  });

  factory UserApp.fromMap(String uid, Map<String, dynamic> data) {
    return UserApp(
      uid: uid,
      email: data['email'] ?? '',
      pseudo: data['pseudo'] ?? '',
      role: data['role'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'pseudo': pseudo,
      'role': role,
    };
  }
}
