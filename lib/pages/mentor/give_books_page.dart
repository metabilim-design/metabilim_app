import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiveBooksPage extends StatefulWidget {
  final List<dynamic> topics;
  const GiveBooksPage({super.key, required this.topics});

  @override
  State<GiveBooksPage> createState() => _GiveBooksPageState();
}

class _GiveBooksPageState extends State<GiveBooksPage> {
  // Seçimler için değişkenler
  String? _selectedLevel;
  String? _selectedBookType;
  String? _selectedSubject;
  String? _selectedPublicationYear; // YENİ: Basım yılı için state
  final TextEditingController _publisherController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  // Ders ve Yıl listeleri
  final List<String> _tytSubjects = [
    'Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'
  ];
  final List<String> _aytSubjects = [
    'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2', 'Felsefe Grubu'
  ];

  // YENİ: Basım yılı listesi oluşturuldu
  final List<String> _publicationYears = List.generate(
    10, // 2016-17'den 2025-26'ya 10 dönem var
        (index) {
      final startYear = 2016 + index;
      final endYear = startYear + 1;
      return '$startYear-$endYear';
    },
  ).reversed.toList(); // En yeni yılın başta görünmesi için ters çeviriyoruz

  List<String> _currentSubjects = [];

  @override
  void initState() {
    super.initState();
    // Başlangıçta TYT derslerini göster
    _currentSubjects = _tytSubjects;
    _selectedLevel = 'TYT';
  }

  // Veriyi Firebase'e kaydetme fonksiyonu
  Future<void> _saveBookToFirebase() async {
    // GÜNCELLEME: Form doğrulamasından önce diğer seçimleri kontrol et
    if (_selectedLevel == null || _selectedBookType == null || _selectedPublicationYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm seçimleri yapın.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('books').add({
        'level': _selectedLevel,
        'bookType': _selectedBookType,
        'publicationYear': _selectedPublicationYear, // YENİ: Veritabanına ekle
        'subject': _selectedSubject,
        'publisher': _publisherController.text.trim(),
        'topics': widget.topics,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitap bilgileri başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst); // Ana sayfaya dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt sırasında bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isSaving;
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitap Bilgilerini Girin', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seviye Seçimi (TYT/AYT)
              Text('Seviye Seçin', style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 8),
              _buildChoiceList(['TYT', 'AYT'], _selectedLevel, (String? value) {
                setState(() {
                  _selectedLevel = value;
                  _selectedSubject = null;
                  if (value == 'TYT') _currentSubjects = _tytSubjects;
                  else _currentSubjects = _aytSubjects;
                });
              }),

              const SizedBox(height: 24),

              // Kitap Türü Seçimi
              Text('Kitap Türü Seçin', style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 8),
              _buildChoiceList(['Soru bankası', 'Konu Anlatımı', 'Deneme'], _selectedBookType, (String? value) {
                setState(() => _selectedBookType = value);
              }),

              const SizedBox(height: 24),

              // YENİ BÖLÜM: Basım Yılı Seçimi
              Text('Basım Yılı Seçin', style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 8),
              _buildChoiceList(_publicationYears, _selectedPublicationYear, (String? value) {
                setState(() => _selectedPublicationYear = value);
              }),

              const SizedBox(height: 24),

              // Ders Seçimi
              Text('Ders Seçin', style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                isExpanded: true,
                value: _selectedSubject,
                hint: Text('Ders Seçiniz', style: GoogleFonts.poppins()),
                items: _currentSubjects.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (String? value) => setState(() => _selectedSubject = value),
                validator: (value) => value == null ? 'Lütfen bir ders seçin.' : null,
              ),

              const SizedBox(height: 24),

              // Yayınevi Text Input
              Text('Yayınevi', style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _publisherController,
                decoration: InputDecoration(
                  hintText: 'Yayınevi Adı',
                  hintStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: GoogleFonts.poppins(),
                validator: (value) => value == null || value.isEmpty ? 'Lütfen yayınevi bilgisini girin.' : null,
              ),

              const SizedBox(height: 40),

              // Onayla ve Bitir Butonu
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isBusy ? null : _saveBookToFirebase,
                icon: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.done, color: Colors.white),
                label: Text('Onayla ve Bitir', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Choicelist'ler için yardımcı widget
  Widget _buildChoiceList(List<String> options, String? selectedValue, ValueChanged<String?> onChanged) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(option, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary)),
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (bool selected) {
                if (selected) onChanged(option);
              },
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}