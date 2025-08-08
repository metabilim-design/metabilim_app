import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:metabilim/pages/mentor/confirm_upload_page.dart'; // Yeni onay sayfamız

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMultipleImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty && mounted) {
      final List<File> imageFiles = pickedFiles.map((file) => File(file.path)).toList();
      // Seçilen fotoğrafları onay sayfasına gönder
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmUploadPage(imageFiles: imageFiles),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Eklenmiş kitaplarınız burada listelenecek.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickMultipleImages,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Yeni Kitap Ekle'),
      ),
    );
  }
}