import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/assign_books_page.dart';

class GiveHomeworkPage extends StatefulWidget {
  const GiveHomeworkPage({super.key});

  @override
  State<GiveHomeworkPage> createState() => _GiveHomeworkPageState();
}

class _GiveHomeworkPageState extends State<GiveHomeworkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tytSubjects = [
    'Türkçe', 'Temel Matematik', 'Geometri', 'Fizik', 'Kimya',
    'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'
  ];
  final List<String> _aytSubjects = [
    'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2',
    'Felsefe Grubu', 'AYT Din Kültürü', 'Matematik', 'Geometri',
    'Fizik', 'Kimya', 'Biyoloji'
  ];

  final Map<String, int> _tytSelections = {};
  final Map<String, int> _aytSelections = {};

  final List<int> _etutOptions = List.generate(11, (index) => index);

  final int _totalEtut = 45;
  int _remainingEtut = 45;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    for (var subject in _tytSubjects) { _tytSelections[subject] = 0; }
    for (var subject in _aytSubjects) { _aytSelections[subject] = 0; }
    _calculateRemainingEtut();
  }

  void _calculateRemainingEtut() {
    int usedEtut = 0;
    _tytSelections.forEach((key, value) => usedEtut += value);
    _aytSelections.forEach((key, value) => usedEtut += value);
    setState(() {
      _remainingEtut = _totalEtut - usedEtut;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Haftalık Ödevlendirme', style: GoogleFonts.poppins()),
            Text(
              'Kalan: $_remainingEtut Etüt',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _remainingEtut >= 0 ? Colors.green.shade600 : Colors.red,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TYT'),
            Tab(text: 'AYT'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectList(subjects: _tytSubjects, selections: _tytSelections),
                _buildSubjectList(subjects: _aytSubjects, selections: _aytSelections),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                final List<Map<String, dynamic>> selectedSubjects = [];
                _tytSelections.forEach((subject, etut) {
                  if (etut > 0) {
                    selectedSubjects.add({'subject': subject, 'type': 'TYT', 'etut': etut});
                  }
                });
                _aytSelections.forEach((subject, etut) {
                  if (etut > 0) {
                    selectedSubjects.add({'subject': subject, 'type': 'AYT', 'etut': etut});
                  }
                });

                if (selectedSubjects.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen en az bir derse etüt sayısı atayın.')),
                  );
                  return;
                }

                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AssignBooksPage(selectedSubjects: selectedSubjects)
                ));
              },
              child: Text(
                'İleri',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hatanın olduğu ve şimdi düzeltilmiş olan fonksiyonun tam hali
  Widget _buildSubjectList({required List<String> subjects, required Map<String, int> selections}) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: subjects.length, // Bu satır önemli
      itemBuilder: (context, index) { // Bu parametre zorunlu
        final subject = subjects[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: selections[subject],
                items: _etutOptions.map((int etut) {
                  return DropdownMenuItem<int>(
                    value: etut,
                    child: Text('$etut etüt'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selections[subject] = newValue!;
                    _calculateRemainingEtut();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}