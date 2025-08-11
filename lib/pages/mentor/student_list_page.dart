// lib/pages/mentor/student_list_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_status_tile.dart'; // YENİ: Akıllı kart widget'ını import ediyoruz

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final Stream<QuerySnapshot> _allStudentsStream = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'Ogrenci')
      .snapshots();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // YENİ: Arama Çubuğu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Öğrenci Ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _allStudentsStream,
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Bir hata oluştu.'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Sistemde kayıtlı öğrenci bulunmuyor.'));
              }

              // Arama filtresini uygula
              var students = snapshot.data!.docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                final data = doc.data() as Map<String, dynamic>;
                final fullName = '${data['name']} ${data['surname']}'.toLowerCase();
                return fullName.contains(_searchQuery);
              }).toList();

              if (students.isEmpty) {
                return const Center(child: Text('Arama kriterlerine uyan öğrenci bulunamadı.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  // YENİ: Artık her öğrenci için akıllı bir kart oluşturuyoruz
                  return StudentStatusTile(studentDoc: students[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}