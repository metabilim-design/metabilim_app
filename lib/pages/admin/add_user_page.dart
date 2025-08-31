import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Controller'lar
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Ogrenci';
  bool _isLoading = false;

  List<DocumentSnapshot> _coaches = [];
  String? _selectedCoachId;

  // YENİ: Veli-Öğrenci bağlantısı için
  List<DocumentSnapshot> _students = [];
  String? _selectedStudentId;

  String? _selectedGrade;
  String? _selectedBranch;

  final List<String> _gradeLevels = ['9', '10', '11', '12', 'Mezun'];
  final List<String> _branchLetters = List.generate(12, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));


  @override
  void initState() {
    super.initState();
    _fetchCoaches();
    _fetchStudents(); // YENİ: Öğrencileri çek
  }

  Future<void> _fetchCoaches() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Eğitim Koçu').get();
    if (mounted) {
      setState(() => _coaches = snapshot.docs);
    }
  }

  // YENİ: Tüm öğrencileri çeken fonksiyon
  Future<void> _fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').get();
    if (mounted) {
      setState(() => _students = snapshot.docs);
    }
  }


  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? result;

    switch(_selectedRole) {
      case 'Ogrenci':
        final String className = '${_selectedGrade}-${_selectedBranch!}';
        result = await _authService.registerStudent(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          number: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
          className: className,
          coachUid: _selectedCoachId,
        );
        break;
      case 'Veli':
      // YENİ: Veli kaydı için öğrenci ID'sini gönder
        result = await _authService.registerParent(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
          studentUid: _selectedStudentId,
        );
        break;
      case 'Mentor':
        result = await _authService.registerMentor(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );
        break;
      case 'Eğitim Koçu':
        result = await _authService.registerCoach(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );
        break;
    }

    if(mounted) {
      setState(() => _isLoading = false);
      if(result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı başarıyla eklendi!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
      }
    }
  }

  // ... (dispose metodu aynı)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Kullanıcı Ekle', style: GoogleFonts.poppins())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['Ogrenci', 'Veli', 'Mentor', 'Eğitim Koçu'] // Sıralama değiştirildi
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) {
                  if(value != null) setState(() => _selectedRole = value);
                },
                decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'İsim'),
              const SizedBox(height: 16),
              _buildTextField(_surnameController, 'Soyisim'),
              const SizedBox(height: 16),
              _buildTextField(_identifierController, _selectedRole == 'Ogrenci' ? 'Okul Numarası' : 'Kullanıcı Adı'),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()), validator: (v) => v!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null, obscureText: true),

              if (_selectedRole == 'Ogrenci') ..._buildStudentFields(),
              if (_selectedRole == 'Veli') ..._buildParentFields(),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addUser,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text('Kullanıcıyı Ekle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Öğrenciye özel alanları oluşturan fonksiyon
  List<Widget> _buildStudentFields() {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGrade,
              hint: const Text('Sınıf'),
              items: _gradeLevels.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
              onChanged: (value) => setState(() => _selectedGrade = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (v) => v == null ? 'Zorunlu' : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBranch,
              hint: const Text('Şube'),
              items: _branchLetters.map((branch) => DropdownMenuItem(value: branch, child: Text(branch))).toList(),
              onChanged: (value) => setState(() => _selectedBranch = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (v) => v == null ? 'Zorunlu' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedCoachId,
        hint: const Text('Eğitim Koçu Seçin'),
        items: _coaches.map((doc) {
          final coach = doc.data() as Map<String, dynamic>;
          return DropdownMenuItem(value: doc.id, child: Text('${coach['name']} ${coach['surname']}'));
        }).toList(),
        onChanged: (value) => setState(() => _selectedCoachId = value),
        decoration: const InputDecoration(labelText: 'Eğitim Koçu', border: OutlineInputBorder()),
        validator: (v) => v == null ? 'Koç seçimi zorunludur' : null,
      ),
    ];
  }

  // YENİ: Veliye özel alanları oluşturan fonksiyon
  List<Widget> _buildParentFields() {
    return [
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedStudentId,
        hint: const Text('Öğrenci Seçin'),
        items: _students.map((doc) {
          final student = doc.data() as Map<String, dynamic>;
          return DropdownMenuItem(value: doc.id, child: Text('${student['name']} ${student['surname']}'));
        }).toList(),
        onChanged: (value) => setState(() => _selectedStudentId = value),
        decoration: const InputDecoration(labelText: 'Bağlı Olduğu Öğrenci', border: OutlineInputBorder()),
        validator: (v) => v == null ? 'Öğrenci seçimi zorunludur' : null,
      ),
    ];
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz' : null,
    );
  }
}