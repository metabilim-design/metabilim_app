import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/firebase_options.dart';
import 'package:metabilim/login_page.dart';
// HATA DÜZELTİLDİ: Eksik olan 'provider' paketi buraya eklendi.
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını uygulama başlarken güvenli bir şekilde yüklüyoruz
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Artık 'Provider' tanınıyor ve hata vermeyecek.
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Metabilim',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const LoginPage(),
        debugShowCheckedModeBanner: false, // Sağ üstteki debug yazısını kaldırır
      ),
    );
  }
}