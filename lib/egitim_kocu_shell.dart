import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/profile_page.dart';
import 'package:metabilim/pages/coach/coach_student_list_page.dart'; // YENİ
import 'package:metabilim/pages/coach/assign_homework_page.dart'; // YENİ
import 'package:metabilim/pages/coach/exam_results_page.dart'; // YENİ

class EgitimKocuShell extends StatefulWidget {
  const EgitimKocuShell({super.key});

  @override
  State<EgitimKocuShell> createState() => _EgitimKocuShellState();
}

class _EgitimKocuShellState extends State<EgitimKocuShell> {
  int _selectedIndex = 0;

  // GÜNCELLENDİ: Alt barda gösterilecek sayfalar artık koça özel
  static const List<Widget> _pages = <Widget>[
    CoachStudentListPage(), // Koçun kendi öğrenci listesi
    AssignHomeworkPage(),   // Ödev verme sayfası
    ExamResultsPage(),      // Deneme sonuçları sayfası
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eğitim Koçu Paneli', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Koç kendi profiline gidebilir
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Öğrenciler'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'Ödev Ver'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Deneme Sonuçları'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}