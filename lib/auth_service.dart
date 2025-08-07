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
        return 'Yanlış şifre girdiniz.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // Başarı durumunda null, hata durumunda string mesaj döndürecek şekilde güncellendi
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
        return null; // Başarılı, hata mesajı yok
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code); // Hata mesajını döndür
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

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
        return null; // Başarılı
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code); // Hata mesajını döndür
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  // Giriş fonksiyonu da artık rolü ve hata mesajını döndürecek
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
        return {'success': true, 'role': doc.get('role')}; // Başarılı giriş ve rol
      }
      return {'success': false, 'message': 'Kullanıcı bulunamadı.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)}; // Hata mesajı
    }
  }
}