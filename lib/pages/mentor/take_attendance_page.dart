import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TakeAttendancePage extends StatefulWidget {
  const TakeAttendancePage({super.key});

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedSession;
  List<DocumentSnapshot> _students = [];
  Map<String, String> _attendanceStatus = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _sessions = [
    {'name': 'Öğleden Önce', 'icon': Icons.wb_sunny_outlined},
    {'name': 'Öğleden Sonra', 'icon': Icons.brightness_5_outlined},
    {'name': 'Akşam', 'icon': Icons.nightlight_round},
  ];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    QuerySnapshot studentSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Ogrenci')
        .get();
    if (mounted) {
      setState(() {
        _students = studentSnapshot.docs;
        _isLoading = false;
      });
    }
  }

  void _selectSession(String session) {
    setState(() {
      _selectedSession = session;
      _attendanceStatus = {};
      for (var student in _students) {
        _attendanceStatus[student.id] = 'belirsiz';
      }
    });
  }

  void _markAttendance(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  // YENİ FONKSİYON: Tüm öğrencileri "geldi" olarak işaretler
  void _markAllPresent() {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student.id] = 'geldi';
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_selectedSession == null) return;
    setState(() => _isLoading = true);
    WriteBatch batch = _firestore.batch();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String mentorId = _auth.currentUser!.uid;
    _attendanceStatus.forEach((studentId, status) {
      if (status != 'belirsiz') {
        DocumentReference docRef = _firestore.collection('attendance').doc('${today}_${studentId}_$_selectedSession');
        batch.set(docRef, { 'date': today, 'session': _selectedSession, 'studentUid': studentId, 'status': status, 'mentorUid': mentorId, 'timestamp': FieldValue.serverTimestamp(), });
      }
    });
    await batch.commit();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedSession = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yoklama başarıyla kaydedildi!'), backgroundColor: Colors.green),);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedSession == null
          ? _buildSessionSelection()
          : _buildAttendanceList(),
    );
  }

  Widget _buildSessionSelection() {
    final String formattedDate = DateFormat.yMMMMd('tr_TR').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rtl_outlined,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Yoklama Oturumları',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Lütfen yoklama alınacak oturumu seçin.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'Bugünün Tarihi: $formattedDate',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ..._sessions.map((session) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(session['icon'], color: Theme.of(context).colorScheme.secondary),
                title: Text(session['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectSession(session['name']),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // GÜNCELLENMİŞ WİDGET: "Tümünü Var Yap" butonu eklendi
  Widget _buildAttendanceList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedSession = null),
              ),
              Text(
                _selectedSession!,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _markAllPresent,
                child: Text(
                  'Tümünü Var Yap',
                  style: GoogleFonts.poppins(color: Theme.of(context).primaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: _saveAttendance,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final data = student.data() as Map<String, dynamic>;
              final studentId = student.id;
              final status = _attendanceStatus[studentId] ?? 'belirsiz';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data['name']} ${data['surname']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            Text('No: ${data['number']} | Sınıf: ${data['class'] ?? 'N/A'} | Masa: ${data['deskNumber'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle, color: status == 'geldi' ? Colors.green : Colors.grey),
                            onPressed: () => _markAttendance(studentId, 'geldi'),
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, color: status == 'gelmedi' ? Colors.red : Colors.grey),
                            onPressed: () => _markAttendance(studentId, 'gelmedi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}