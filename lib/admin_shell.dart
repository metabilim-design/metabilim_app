import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/login_page.dart';
import 'package:metabilim/pages/admin/admin_dashboard_page.dart';
import 'package:metabilim/pages/admin/class_management_page.dart';
import 'package:metabilim/pages/admin/coach_management_page.dart';
import 'package:metabilim/pages/admin/digital_lesson_settings_page.dart';
import 'package:metabilim/pages/admin/exam_analysis_page.dart';
import 'package:metabilim/pages/admin/schedule_settings_page.dart';
import 'package:metabilim/pages/admin/user_management_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  // HATA DÜZELTİLDİ: _adminPages listesinden ComputerSchedulePage çıkarıldı.
  // Bu sayfa zaten DigitalLessonSettingsPage'in içinden çağrılıyor.
  static const List<Widget> _adminPages = <Widget>[
    AdminDashboardPage(),
    UserManagementPage(),
    ClassManagementPage(),
    CoachManagementPage(),
    DigitalLessonSettingsPage(), // Bu sayfa bilgisayar listesini gösterir
    ScheduleSettingsPage(),
    ExamAnalysisPage(),
  ];

  // HATA DÜZELTİLDİ: Başlık listesi de sayfa listesiyle uyumlu hale getirildi.
  static const List<String> _pageTitles = <String>[
    'Genel Bakış',
    'Kullanıcı Yönetimi',
    'Sınıf Yönetimi',
    'Eğitim Koçu Yönetimi',
    'Dijital Ders Ayarları', // "Bilgisayar Ders Programı" başlığı kaldırıldı
    'Etüt Saat Ayarları',
    'Deneme Analizi',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Menüyü kapat
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Admin Paneli',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildDrawerItem(icon: Icons.dashboard_outlined, title: 'Genel Bakış', index: 0),
            _buildDrawerItem(icon: Icons.people_alt_outlined, title: 'Kullanıcı Yönetimi', index: 1),
            _buildDrawerItem(icon: Icons.class_outlined, title: 'Sınıf Yönetimi', index: 2),
            _buildDrawerItem(icon: Icons.school_outlined, title: 'Eğitim Koçu Yönetimi', index: 3),
            _buildDrawerItem(icon: Icons.computer_outlined, title: 'Dijital Ders Ayarları', index: 4),
            _buildDrawerItem(icon: Icons.timer_outlined, title: 'Etüt Saat Ayarları', index: 5),
            _buildDrawerItem(icon: Icons.analytics_outlined, title: 'Deneme Analizi', index: 6),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _adminPages.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required int index}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () => _onItemTapped(index),
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }
}