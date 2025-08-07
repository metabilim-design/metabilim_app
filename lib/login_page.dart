import 'package:flutter/material.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/register_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/student_shell.dart'; // YENİ: Öğrenci ana iskeletini import ediyoruz

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Ogrenci';
  bool _isLoading = false;

  // Bildirimleri göstermek için yardımcı fonksiyon
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return; // Sayfa aktif değilse işlem yapma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String identifier = _identifierController.text;
      String password = _passwordController.text;

      // Admin özel durumu
      if (_selectedRole == 'Admin' && identifier == 'admin' && password == 'admin') {
        _showFeedback('Admin girişi başarılı!');
        // TODO: Admin paneline yönlendir
        setState(() => _isLoading = false);
        return;
      }

      var result = await _authService.signIn(
        identifier: identifier,
        password: password,
        role: _selectedRole,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showFeedback('${result['role']} olarak giriş yapıldı.');

        // GÜNCELLENDİ: Role göre yönlendirme
        if (result['role'] == 'Ogrenci') {
          Navigator.pushReplacement( // Geri dönememesi için pushReplacement
            context,
            MaterialPageRoute(builder: (context) => const StudentShell()),
          );
        }
        // TODO: Diğer roller için yönlendirmeler buraya eklenecek
        // else if (result['role'] == 'Mentor') {
        //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MentorShell()));
        // }

      } else {
        _showFeedback(result['message'], isError: true);
      }
    }
  }

  String getIdentifierLabel() {
    switch (_selectedRole) {
      case 'Ogrenci':
        return 'Okul Numarası';
      case 'Mentor':
        return 'Kullanıcı Adı';
      case 'Admin':
        return 'Admin Kullanıcı Adı';
      default:
        return 'Kimlik';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          // Tablet ve geniş ekran uyumluluğu için
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/image_0d0f89.png', height: 120),
                    const SizedBox(height: 50),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Giriş Tipi', border: OutlineInputBorder()),
                      items: ['Ogrenci', 'Mentor', 'Admin'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) => setState(() => _selectedRole = newValue!),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _identifierController,
                      decoration: InputDecoration(labelText: getIdentifierLabel(), border: const OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Şifre boş olamaz' : null,
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _login,
                      child: Text('Giriş Yap', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                      child: Text('Hesabın yok mu? Kayıt Ol', style: GoogleFonts.poppins(color: const Color(0xFF00A99D))),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}