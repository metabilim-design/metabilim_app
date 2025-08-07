import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/student_detail_page.dart'; // YENİ: Detay sayfasını import ediyoruz

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final Stream<QuerySnapshot> _studentsStream = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'Ogrenci')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _studentsStream,
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

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            String studentName = '${data['name']} ${data['surname']}';
            String studentNumber = data['number'] ?? 'Numara Yok';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                      data['name'] != null && data['name'].isNotEmpty ? data['name'][0] : 'Ö',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
                title: Text(studentName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text('Numara: $studentNumber'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                // DEĞİŞİKLİK BURADA: Artık detay sayfasına yönlendiriyoruz
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => StudentDetailPage(
                            studentId: document.id, // Öğrencinin benzersiz ID'si
                            studentName: studentName, // Öğrencinin tam adı
                          )
                      )
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}