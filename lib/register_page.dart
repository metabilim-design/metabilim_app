import 'package:flutter/material.dart';
import 'package:metabilim/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ... (İçerideki fonksiyonlar ve değişkenler aynı kalıyor)
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _numberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedUserType = 'Ogrenci';
  bool _isLoading = false;

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? errorMessage;
      if (_selectedUserType == 'Ogrenci') {
        errorMessage = await _authService.registerStudent(
          name: _nameController.text, surname: _surnameController.text,
          number: _numberController.text, password: _passwordController.text,
        );
      } else {
        errorMessage = await _authService.registerMentor(
          name: _nameController.text, surname: _surnameController.text,
          username: _usernameController.text, password: _passwordController.text,
        );
      }

      setState(() => _isLoading = false);
      if (errorMessage == null) {
        _showFeedback('Kayıt başarılı! Giriş yapabilirsiniz.');
        Navigator.pop(context);
      } else {
        _showFeedback(errorMessage, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Hesap Oluştur', style: GoogleFonts.poppins(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        // YENİ: Tablet ve geniş ekran uyumluluğu için eklendi
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/image_0d0f89.png',
                    height: 100,
                  ),
                  const SizedBox(height: 30),

                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: const InputDecoration(labelText: 'Hesap Tipi', border: OutlineInputBorder()),
                    items: ['Ogrenci', 'Mentor'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedUserType = newValue!),
                  ),

                  if (_selectedUserType == 'Ogrenci') ...[
                    _buildTextField(_nameController, 'İsim'),
                    _buildTextField(_surnameController, 'Soyisim'),
                    _buildTextField(_numberController, 'Okul Numarası', keyboardType: TextInputType.number),
                    _buildTextField(_passwordController, 'Şifre', obscureText: true),
                  ] else ...[
                    _buildTextField(_nameController, 'İsim'),
                    _buildTextField(_surnameController, 'Soyisim'),
                    _buildTextField(_usernameController, 'Kullanıcı Adı'),
                    _buildTextField(_passwordController, 'Şifre', obscureText: true),
                  ],

                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _register,
                    child: Text('Hesabı Oluştur', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? '$label boş bırakılamaz.' : null,
      ),
    );
  }
}