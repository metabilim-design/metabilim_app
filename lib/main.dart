import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metabilim/firebase_options.dart';
import 'package:metabilim/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('tr_TR', null);
  runApp(const MetabilimApp());
}

class MetabilimApp extends StatelessWidget {
  const MetabilimApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ana renklerimizi burada tanımlayalım
    const Color primaryColor = Color(0xFF003366);
    const Color scaffoldBackgroundColor = Color(0xFFF5F5F7);

    return MaterialApp(
      title: 'Metabilim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primaryColor,
          secondary: const Color(0xFF00A99D),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),

        // DEĞİŞİKLİK BURADA: AppBar temasını global olarak ayarlıyoruz
        appBarTheme: AppBarTheme(
          backgroundColor: scaffoldBackgroundColor, // Arka planı saydam/sayfa rengi yap
          foregroundColor: primaryColor, // İçindeki yazı ve ikonları ana rengimiz yap
          elevation: 0, // Gölgeyi kaldır
          titleTextStyle: GoogleFonts.poppins(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600
          ),
          iconTheme: const IconThemeData(color: primaryColor), // Geri oku vs.
        ),
      ),
      home: const LoginPage(),
    );
  }
}