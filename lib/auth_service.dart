import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hata kodlarını Türkçe'ye çeviren yardımcı fonksiyon
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu email/kullanıcı adı zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz bir email formatı girdiniz.';
      case 'user-not-found':
        return 'Bu kullanıcı adı veya numaraya sahip bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Mevcut şifrenizi yanlış girdiniz.'; // Bu mesajı şifre değiştirme için güncelledik
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // ÖĞRENCİ KAYIT
  Future<String?> registerStudent({
    required String name,
    required String surname,
    required String number,
    required String password,
  }) async {
    String email = '$number@metabilim.app';
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name, 'surname': surname, 'number': number, 'email': email, 'role': 'Ogrenci',
        });
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  // MENTOR KAYIT
  Future<String?> registerMentor({
    required String name,
    required String surname,
    required String username,
    required String password,
  }) async {
    String email = '$username@metabilim.mentor';
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name, 'surname': surname, 'username': username, 'email': email, 'role': 'Mentor',
        });
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  // GİRİŞ YAPMA
  Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
    required String role,
  }) async {
    String email;
    if (role == 'Ogrenci') {
      email = '$identifier@metabilim.app';
    } else {
      email = '$identifier@metabilim.mentor';
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return {'success': true, 'role': doc.get('role')};
      }
      return {'success': false, 'message': 'Kullanıcı bulunamadı.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    }
  }

  // KULLANICI ROLÜNÜ GETİRME
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.get('role');
    } catch (e) {
      return null;
    }
  }

  // GÜVENLİ ŞİFRE DEĞİŞTİRME FONKSİYONU
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword
  }) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        // 1. Kullanıcıyı mevcut şifresiyle yeniden doğrula
        AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: oldPassword
        );
        await user.reauthenticateWithCredential(credential);

        // 2. Yeniden doğrulama başarılı olursa, yeni şifreyi ayarla
        await user.updatePassword(newPassword);
        return null; // Başarılı, hata yok
      } on FirebaseAuthException catch (e) {
        return _getErrorMessage(e.code); // Hata mesajını döndür (örn: wrong-password)
      } catch (e) {
        return "Şifre güncellenirken bir hata oluştu.";
      }
    }
    return "Önce giriş yapmanız gerekiyor.";
  }

  // ÇIKIŞ YAPMA FONKSİYONU
  Future<void> signOut() async {
    await _auth.signOut();
  }
}