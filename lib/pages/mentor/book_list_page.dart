import 'package:flutter/material.dart';

class BookListPage extends StatelessWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bu sayfanın kendi AppBar'ına ihtiyacı yok çünkü shell'de var.
      body: const Center(
        child: Text('Kitap Listesi Sayfası'),
      ),
    );
  }
}