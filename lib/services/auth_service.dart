import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'sync_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SyncService _syncService = SyncService();

  // Şu an giriş yapmış kullanıcıyı verir (giriş yoksa null)
  User? get currentUser => _auth.currentUser;

  // Giriş durumu değişikliklerini dinlemek için stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kullanıcı giriş yapmış mı?
  bool get isSignedIn => _auth.currentUser != null;

  // Google ile giriş yap
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // Web'de Firebase'in kendi popup yöntemini kullanıyoruz
        final googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobil (Android/iOS) için google_sign_in paketi
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // Kullanıcı giriş penceresini iptal etti
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // Giriş başarılıysa otomatik olarak iki yönlü senkronizasyonu başlat
      if (userCredential.user != null) {
        _syncService.syncAll().catchError((e) {
          print('Otomatik senkronizasyon hatası: $e');
        });
      }

      return userCredential.user;
    } catch (e) {
      print('Google ile giriş hatası: $e');
      return null;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}