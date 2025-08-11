import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/auth_service.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Form controller'ları
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Ogrenci';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    String? error;
    if (_selectedRole == 'Ogrenci') {
      error = await _authService.registerStudent(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        number: _identifierController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else if (_selectedRole == 'Mentor') {
      error = await _authService.registerMentor(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        username: _identifierController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı başarıyla oluşturuldu!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Sayfayı kapat, listeleme ekranına dön
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $error'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStudent = _selectedRole == 'Ogrenci';

    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Kullanıcı Ekle', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
                items: ['Ogrenci', 'Mentor'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedRole = newValue!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'İsim', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'İsim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Soyisim', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Soyisim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identifierController,
                decoration: InputDecoration(labelText: isStudent ? 'Okul Numarası' : 'Kullanıcı Adı', border: const OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Geçici Şifre', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Şifre boş olamaz' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveUser,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text('Kullanıcıyı Kaydet', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}