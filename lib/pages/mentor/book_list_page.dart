import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:metabilim/pages/mentor/confirm_upload_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore paketi eklendi

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('books').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Veriler yüklenirken bir hata oluştu.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Henüz eklenmiş bir kitabınız yok.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final books = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Text(
                    '${book['subject']} - ${book['publisher']}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Seviye: ${book['level']}, Tür: ${book['bookType']}',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Buraya kitap detay sayfasını açma navigasyonunu ekle
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => BookDetailPage(book: book)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickMultipleImages,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        label: Text('Yeni Kitap Ekle', style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }
}