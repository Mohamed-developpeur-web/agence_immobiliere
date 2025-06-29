import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyAA2kJXUViuOuHjOekWw2ZDBeN3UiXaRP4",
      authDomain: "agence-immobiliere-a4dec.firebaseapp.com",
      projectId: "agence-immobiliere-a4dec",
      storageBucket: "agence-immobiliere-a4dec.appspot.com", // ✅ corrigé ici
      messagingSenderId: "507757354869",
      appId: "1:507757354869:web:977fafb0924a4e8c44bd3c",
      measurementId: "G-PJTDWWK66K",
    );
  }
}
