import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GiveHomeworkPage extends StatefulWidget {
  const GiveHomeworkPage({super.key});

  @override
  State<GiveHomeworkPage> createState() => _GiveHomeworkPageState();
}

class _GiveHomeworkPageState extends State<GiveHomeworkPage> {
  // --- State Değişkenleri ---
  int _currentStep = 1;
  DocumentSnapshot? _selectedStudent;
  DateTimeRange? _selectedDateRange;
  String _levelFilter = 'TYT';
  final List<String> _selectedSubjects = [];
  final Map<String, List<DocumentSnapshot>> _selectedBooksBySubject = {};
  final Map<String, Map<String, List<Map<String, dynamic>>>> _selectedTopicsByBook = {};
  final Map<String, int> _etutCounts = {}; // YENİ: Etüt sayılarını tutar

  // --- Sabit Listeler ---
  final List<String> _tytSubjects = ['Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'];
  final List<String> _aytSubjects = ['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2', 'Felsefe Grubu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: GoogleFonts.poppins()),
        leading: _currentStep > 1 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)) : null,
      ),
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 1: return 'Öğrenci Seçin';
      case 2: return 'Tarih Aralığı Seçin';
      case 3: return 'Dersleri Seçin';
      case 4: return 'Kitapları Seçin';
      case 5: return 'Konuları Seçin';
      case 6: return 'Etüt Sayısı Belirle';
      default: return 'Program Özeti';
    }
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 1: return _buildStudentSelection();
      case 2: return _buildDateRangeSelection();
      case 3: return _buildSubjectSelection();
      case 4: return _buildBookSelection();
      case 5: return _buildTopicSelection();
      case 6: return _buildEtutSelection(); // YENİ: Özet ve Etüt Sayısı Seçim Adımı
      default: return Container();
    }
  }

  // --- Adım 1: ÖĞRENCİ SEÇİMİ ---
  Widget _buildStudentSelection() {
    final stream = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Öğrenci bulunamadı.'));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final student = snapshot.data!.docs[index];
          final data = student.data() as Map<String, dynamic>;
          return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(
            leading: CircleAvatar(child: Text(data['name'][0])),
            title: Text('${data['name']} ${data['surname']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text('No: ${data['number'] ?? 'N/A'}', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => setState(() { _selectedStudent = student; _currentStep = 2; }),
          ));
        });
      },
    );
  }

  // --- Adım 2: TARİH ARALIĞI SEÇİMİ ---
  Widget _buildDateRangeSelection() {
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 16),
      Text('Program için bir başlangıç ve bitiş tarihi seçin.', style: GoogleFonts.poppins(fontSize: 18), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildDateDisplay('Başlangıç Tarihi', _selectedDateRange?.start),
        const SizedBox(height: 50, child: VerticalDivider(thickness: 1)),
        _buildDateDisplay('Bitiş Tarihi', _selectedDateRange?.end),
      ]))),
      const SizedBox(height: 16),
      OutlinedButton.icon(icon: const Icon(Icons.date_range_outlined), label: Text('Tarih Aralığı Seç', style: GoogleFonts.poppins()), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _pickDateRange),
      const Spacer(),
      _buildStepNavigationBar(
        onNextPressed: _selectedDateRange == null ? null : () => setState(() => _currentStep = 3),
      ),
    ]));
  }

  // --- Adım 3: DERS SEÇİMİ ---
  Widget _buildSubjectSelection() {
    final subjectsToList = _levelFilter == 'TYT' ? _tytSubjects : _aytSubjects;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16.0), child: SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'TYT', label: Text('TYT')), ButtonSegment(value: 'AYT', label: Text('AYT'))],
        selected: {_levelFilter},
        onSelectionChanged: (selection) => setState(() => _levelFilter = selection.first),
      )),
      Expanded(child: ListView.builder(itemCount: subjectsToList.length, itemBuilder: (context, index) {
        final subject = subjectsToList[index];
        final uniqueSubjectId = '$_levelFilter-$subject';
        final isSelected = _selectedSubjects.contains(uniqueSubjectId);
        return CheckboxListTile(
          title: Text(subject, style: GoogleFonts.poppins()),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) _selectedSubjects.add(uniqueSubjectId);
              else _selectedSubjects.remove(uniqueSubjectId);
            });
          },
        );
      })),
      _buildStepNavigationBar(
        onNextPressed: _selectedSubjects.isEmpty ? null : () => setState(() => _currentStep = 4),
      ),
    ]);
  }

  // --- Adım 4: KİTAP SEÇİMİ ---
  Widget _buildBookSelection() {
    final cleanSubjectNames = _selectedSubjects.map((uniqueId) => uniqueId.split('-').last).toSet().toList();
    if (cleanSubjectNames.isEmpty) {
      return const Center(child: Text('Lütfen önce ders seçin.'));
    }
    final booksStream = FirebaseFirestore.instance.collection('books').where('subject', whereIn: cleanSubjectNames).snapshots();

    return Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: booksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('Seçilen derslere uygun kitap bulunamadı.', style: GoogleFonts.poppins()));

          final allBooksForSubjects = snapshot.data!.docs;

          final filteredBooks = allBooksForSubjects.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return false;

            final level = data['level'] as String?;
            final subject = data['subject'] as String?;
            if (level == null || subject == null) return false;

            final bookUniqueId = '$level-$subject';
            return _selectedSubjects.contains(bookUniqueId);
          }).toList();

          if (filteredBooks.isEmpty) {
            return Center(child: Text('Seçilen seviyeye uygun kitap bulunamadı.', style: GoogleFonts.poppins()));
          }

          final groupedBooks = <String, List<DocumentSnapshot>>{};
          for (var doc in filteredBooks) {
            final subject = doc['subject'] as String;
            groupedBooks.putIfAbsent(subject, () => []).add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0), itemCount: cleanSubjectNames.length,
            itemBuilder: (context, index) {
              final subject = cleanSubjectNames[index];
              final booksForSubject = groupedBooks[subject] ?? [];
              if (booksForSubject.isEmpty) return const SizedBox.shrink();

              return Card(margin: const EdgeInsets.symmetric(vertical: 8.0), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(left: 8.0, bottom: 8.0), child: Text('$subject İçin Kitap Seçin', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
                ...booksForSubject.map((bookDoc) {
                  final bookData = bookDoc.data() as Map<String, dynamic>;
                  final isSelected = _selectedBooksBySubject[subject]?.any((doc) => doc.id == bookDoc.id) ?? false;
                  return CheckboxListTile(title: Text(bookData['publisher'], style: GoogleFonts.poppins()), subtitle: Text(bookData['bookType']), value: isSelected, onChanged: (bool? value) {
                    setState(() {
                      _selectedBooksBySubject.putIfAbsent(subject, () => []);
                      if (value == true) {
                        if (!_selectedBooksBySubject[subject]!.any((doc) => doc.id == bookDoc.id)) {
                          _selectedBooksBySubject[subject]!.add(bookDoc);
                        }
                      } else {
                        _selectedBooksBySubject[subject]!.removeWhere((doc) => doc.id == bookDoc.id);
                      }
                    });
                  });
                }).toList(),
              ])));
            },
          );
        },
      )),
      _buildStepNavigationBar(
        onNextPressed: _selectedBooksBySubject.values.every((list) => list.isEmpty) ? null : () => setState(() => _currentStep = 5),
      ),
    ]);
  }

  // --- Adım 5: KONU SEÇİMİ ---
  Widget _buildTopicSelection() {
    return Column(children: [ Expanded(child: ListView.builder(padding: const EdgeInsets.all(8.0), itemCount: _selectedSubjects.length, itemBuilder: (context, subjectIndex) {
      final subjectUniqueId = _selectedSubjects[subjectIndex];
      final subject = subjectUniqueId.split('-').last;
      final selectedBooks = _selectedBooksBySubject[subject] ?? [];
      if (selectedBooks.isEmpty) return const SizedBox.shrink();
      return Card(margin: const EdgeInsets.symmetric(vertical: 8.0), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 8.0, bottom: 4.0), child: Text(subject, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
        ...selectedBooks.map((bookDoc) {
          final bookData = bookDoc.data() as Map<String, dynamic>;
          final topics = List<Map<String, dynamic>>.from(bookData['topics'] ?? []);
          return ExpansionTile(title: Text('${bookData['publisher']} - ${bookData['bookType']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), children: topics.map((topic) {
            final isSelected = _selectedTopicsByBook[subject]?[bookDoc.id]?.any((t) => t['konu'] == topic['konu']) ?? false;
            return CheckboxListTile(title: Text(topic['konu'] ?? ''), subtitle: Text('Sayfa: ${topic['sayfa'] ?? ''}'), value: isSelected, onChanged: (bool? value) {
              setState(() {
                _selectedTopicsByBook.putIfAbsent(subject, () => {});
                _selectedTopicsByBook[subject]!.putIfAbsent(bookDoc.id, () => []);
                if (value == true) {
                  if (!_selectedTopicsByBook[subject]![bookDoc.id]!.any((t) => t['konu'] == topic['konu'])) {
                    _selectedTopicsByBook[subject]![bookDoc.id]!.add(topic);
                  }
                } else {
                  _selectedTopicsByBook[subject]![bookDoc.id]!.removeWhere((t) => t['konu'] == topic['konu']);
                }
              });
            });
          }).toList());
        }).toList(),
      ])));
    })), _buildStepNavigationBar(onNextPressed: _selectedTopicsByBook.values.every((map) => map.values.every((list) => list.isEmpty)) ? null : () => setState(() => _currentStep = 6)) ]);
  }

  // --- Adım 6: ETÜT SAYISI BELİRLEME ---
  Widget _buildEtutSelection() {
    final List<Map<String, dynamic>> allSelectedTopics = [];
    _selectedTopicsByBook.forEach((subject, books) {
      books.forEach((bookId, topics) {
        topics.forEach((topic) {
          final bookDoc = _selectedBooksBySubject[subject.split('-').last]?.firstWhere((doc) => doc.id == bookId);
          final bookData = bookDoc?.data() as Map<String, dynamic>;
          final fullSubjectName = _selectedSubjects.firstWhere((id) => id.endsWith(subject.split('-').last));

          allSelectedTopics.add({
            'subject': fullSubjectName,
            'bookPublisher': bookData['publisher'],
            'bookType': bookData['bookType'],
            'konu': topic['konu'],
            'sayfa': topic['sayfa'],
            'id': '$subject-$bookId-${topic['konu']}',
          });
        });
      });
    });

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: allSelectedTopics.length,
            itemBuilder: (context, index) {
              final topic = allSelectedTopics[index];
              final uniqueId = topic['id'] as String;
              final currentEtutCount = _etutCounts[uniqueId] ?? 1;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${topic['subject'].split('-').last} / ${topic['bookPublisher']} - ${topic['bookType']}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${topic['konu']} (Sayfa: ${topic['sayfa']})',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: currentEtutCount,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          underline: const SizedBox(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _etutCounts[uniqueId] = newValue;
                              });
                            }
                          },
                          items: <int>[1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value Etüt', style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildStepNavigationBar(
          onNextPressed: _etutCounts.isEmpty ? null : () => setState(() => _currentStep = 7),
        ),
      ],
    );
  }

  // --- Yardımcı Widget'lar ve Fonksiyonlar ---
  Widget _buildStepNavigationBar({required VoidCallback? onNextPressed}) {
    return Padding(padding: const EdgeInsets.all(16.0), child: ElevatedButton.icon(
      style: _getPrimaryButtonStyle(fullWidth: true),
      onPressed: onNextPressed,
      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      label: Text('Devam Et', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
    ));
  }

  ButtonStyle _getPrimaryButtonStyle({bool fullWidth = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      minimumSize: fullWidth ? const Size.fromHeight(50) : null,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Widget _buildDateDisplay(String label, DateTime? date) {
    return Column(children: [ Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade600)), const SizedBox(height: 8), Text(date != null ? DateFormat.yMMMMd('tr_TR').format(date) : '-- / -- / ----', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))]);
  }
}