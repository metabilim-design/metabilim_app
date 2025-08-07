import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Etkinlikleri modellemek için basit bir sınıf
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
  // DEĞİŞİKLİK: Takvim state'leri yerine sadece seçili tarihi tutan tek bir değişken
  DateTime _selectedDate = DateTime.now();

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
    _loadUserData();
  }

  // Giriş yapan kullanıcının adını Firestore'dan çeker (DEĞİŞİKLİK YOK)
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) { // Widget hala ağaçtaysa state'i güncelle
        setState(() {
          _userName = userData.get('name');
          _isLoading = false;
        });
      }
    }
  }

  // Seçilen güne ait etkinlikleri getiren fonksiyon (DEĞİŞİKLİK YOK)
  List<Event> _getEventsForDay(DateTime day) {
    // Saat, dakika ve saniye bilgilerini yok sayarak sadece tarihi karşılaştırırız
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // YENİ FONKSİYON: Tarihi bir gün ileri veya geri almak için
  void _changeDay(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: amount));
    });
  }

  @override
  Widget build(BuildContext context) {
    // DEĞİŞİKLİK: Seçili güne ait etkinlikleri burada alıyoruz
    final selectedEvents = _getEventsForDay(_selectedDate);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hoş Geldin Mesajı (DEĞİŞİKLİK YOK)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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

          // YENİ WIDGET: Günlük tarih şeridi
          _buildDateScroller(),

          const SizedBox(height: 8.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Günün Programı',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF003366).withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Seçilen Güne Ait Etkinlikler Listesi (DEĞİŞİKLİK YOK)
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
              child: Text(
                'Bugün için planlanmış bir etkinlik yok.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 4.0),
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return _buildEventTile(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  // YENİ WIDGET: Üst kısımdaki yatay tarih seçiciyi oluşturan widget.
  Widget _buildDateScroller() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Önceki güne gitmek için kullanılan ikon butonu.
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
            onPressed: () => _changeDay(-1),
          ),
          // Tarihin gösterildiği alan.
          Text(
            // intl paketini kullanarak tarihi "9 Ağustos Cuma" formatında gösterir.
            DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003366),
            ),
          ),
          // Sonraki güne gitmek için kullanılan ikon butonu.
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueGrey),
            onPressed: () => _changeDay(1),
          ),
        ],
      ),
    );
  }

  // Etkinlik listesi elemanını oluşturan fonksiyon (DEĞİŞİKLİK YOK)
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
        leading: SizedBox(
          width: 50,
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