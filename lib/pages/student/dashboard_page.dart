import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Etkinlikleri modellemek için basit bi
// r sınıf
class Event {
  final String title;
  final String time;
  final bool attended; // true: katıldı, false: katılmadı

  Event({required this.title, required this.time, required this.attended});
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Takvimin durumunu yöneten değişkenler
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _userName = '...'; // Başlangıçta boş
  bool _isLoading = true;

  // TODO: Bu veriler daha sonra Firestore'dan çekilecek. Şimdilik sahte veri.
  final Map<DateTime, List<Event>> _events = {
    DateTime.utc(2025, 8, 7): [
      Event(title: 'Matematik - Temel Kavramlar', time: '10:00 - 10:50', attended: true),
      Event(title: 'Fizik - Vektörler', time: '11:00 - 11:50', attended: true),
      Event(title: 'Ödev: Matematik Testi', time: 'Son Teslim: 23:59', attended: true),
    ],
    DateTime.utc(2025, 8, 8): [
      Event(title: 'Kimya - Mol Kavramı', time: '09:00 - 09:50', attended: false),
      Event(title: 'Biyoloji - Hücre', time: '10:00 - 10:50', attended: true),
    ],
    DateTime.utc(2025, 8, 25): [
      Event(title: 'Türkçe - Paragraf Çözümü', time: '13:00 - 13:50', attended: true),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserData();
  }

  // Giriş yapan kullanıcının adını Firestore'dan çeker
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userName = userData.get('name');
        _isLoading = false;
      });
    }
  }

  // Seçilen güne ait etkinlikleri getiren fonksiyon
  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hoş Geldin Mesajı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Text(
                    'Hoş Geldin, $_userName',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003366),
                    ),
                  ),
              ],
            ),
          ),

          // İnteraktif Takvim
          TableCalendar(
            locale: 'tr_TR', // Takvimi Türkçeleştirir
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // Seçilen güne odaklan
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0x8000A99D), // Bugünün rengi (yarı saydam turkuaz)
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF003366), // Seçili günün rengi (koyu mavi)
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false, // 2 Hafta/Hafta butonunu gizler
            ),
          ),

          const SizedBox(height: 8.0),

          // Seçilen Güne Ait Etkinlikler Listesi
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay!)[index];
                return _buildEventTile(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Etkinlik listesi elemanını oluşturan fonksiyon
  Widget _buildEventTile(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        // DEĞİŞİKLİK BURADA: İkonu daha anlaşılır hale getiriyoruz
        leading: SizedBox(
          width: 50, // Sabit bir genişlik vererek hizalamayı güzelleştiriyoruz
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Durum',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Icon(
                event.attended ? Icons.check_circle : Icons.cancel,
                color: event.attended ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ],
          ),
        ),
        title: Text(event.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(event.time, style: GoogleFonts.poppins()),
        onTap: () {},
      ),
    );
  }
}