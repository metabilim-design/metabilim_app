import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/login_page.dart';
import 'package:metabilim/pages/admin/user_management_page.dart';
import 'package:metabilim/pages/admin/schedule_settings_page.dart';
import 'package:metabilim/pages/admin/admin_dashboard_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  // Menüde gösterilecek sayfaları burada listeliyoruz
  static const List<Widget> _adminPages = <Widget>[
    AdminDashboardPage(),
    UserManagementPage(),
    ScheduleSettingsPage(),
  ];

  // Sayfalara göre AppBar başlığını değiştirmek için
  static const List<String> _pageTitles = <String>[
    'Genel Bakış',
    'Kullanıcı Yönetimi',
    'Etüt Saat Ayarları',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Menüyü kapat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Admin Paneli',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Genel Bakış'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Kullanıcı Yönetimi'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Etüt Saat Ayarları'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await AuthService().signOut();
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
}