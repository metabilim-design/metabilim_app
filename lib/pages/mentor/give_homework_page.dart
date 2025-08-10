import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math';

// --- YARDIMCI SINIFLAR ---
class ScheduleTask {
  final Map<String, dynamic> data;
  ScheduleTask({required this.data});
}
class ScheduleDay {
  final DateTime date;
  List<ScheduleTask?> tasks;
  ScheduleDay({required this.date, required this.tasks});
}

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
  final Map<String, List<DocumentSnapshot>> _selectedPracticesBySubject = {};
  final Map<String, Map<String, List<Map<String, dynamic>>>> _selectedTopicsByBook = {};
  final Map<String, int> _etutCounts = {};
  final Map<String, TextEditingController> _endPageControllers = {};
  final List<TextEditingController> _digitalEtutControllers = List.generate(50, (_) => TextEditingController());
  bool _isSaving = false;

  late PageController _pageController;
  int _currentPageIndex = 0;
  List<ScheduleDay> _finalSchedule = [];

  bool _isSwapMode = false;
  Map<String, int>? _firstSelectedItem;

  // --- Sabit Listeler ve Zaman Dilimleri ---
  final Map<String, String> _subjectTypes = {
    'Türkçe': 'Sözel', 'Edebiyat': 'Sözel', 'Tarih': 'Sözel', 'Tarih-1': 'Sözel', 'Tarih-2': 'Sözel',
    'Coğrafya': 'Sözel', 'Coğrafya-1': 'Sözel', 'Coğrafya-2': 'Sözel', 'Felsefe': 'Sözel', 'Felsefe Grubu': 'Sözel', 'Din Kültürü': 'Sözel',
    'Matematik': 'Sayısal', 'Fizik': 'Sayısal', 'Kimya': 'Sayısal', 'Biyoloji': 'Sayısal'
  };
  final List<String> _tytSubjects = ['Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'];
  final List<String> _aytSubjects = ['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2', 'Felsefe Grubu'];
  final List<String> _daysOfWeek = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  final List<String> _weekdayTimes = ['09:00\n09:40', '09:50\n10:30', '10:40\n11:20', '11:30\n12:10', '13:30\n14:10', '14:20\n15:00', '15:10\n15:50', '16:00\n16:40', '16:50\n17:30', '17:40\n18:20'];
  final List<String> _saturdayTimes = ['13:30\n14:10', '14:20\n15:00', '15:20\n16:10', '16:20\n17:10', '17:20\n18:10'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    for (var controller in _endPageControllers.values) { controller.dispose(); }
    for (var controller in _digitalEtutControllers) { controller.dispose(); }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: GoogleFonts.poppins()),
        leading: _isSwapMode ? IconButton(icon: const Icon(Icons.cancel_outlined), tooltip: 'Değişimi İptal Et', onPressed: _cancelSwap)
            : (_currentStep > 1 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
          if (_currentStep == 3) _selectedDateRange = null;
          if (_currentStep == 4) _selectedSubjects.clear();
          if (_currentStep == 5) { _selectedBooksBySubject.clear(); _selectedPracticesBySubject.clear(); }
          if (_currentStep == 6) _selectedTopicsByBook.clear();
          if (_currentStep == 7) { _etutCounts.clear(); _endPageControllers.clear(); }
          if (_currentStep == 8) _digitalEtutControllers.forEach((c) => c.clear());
          if (_currentStep == 10) _finalSchedule = [];
          setState(() => _currentStep--);
        }) : null),
        bottom: _isSwapMode ? PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Container(
            color: Colors.amber.shade700,
            width: double.infinity,
            padding: const EdgeInsets.all(4.0),
            alignment: Alignment.center,
            child: Text('Değiştirmek istediğiniz diğer görevi seçin', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          ),
        ) : null,
      ),
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 1: return 'Öğrenci Seçin';
      case 2: return 'Program Tipi Seçin';
      case 3: return 'Tarih Aralığı Seçin';
      case 4: return 'Dersleri Seçin';
      case 5: return 'Materyal Seçimi';
      case 6: return 'Konuları Seçin';
      case 7: return 'Etüt & Sayfa Ayarla';
      case 8: return 'Dijital Etütleri Belirle';
      case 9: return 'Program Özeti ve Onay';
      case 10: return 'Program Önizleme ve Düzenleme';
      default: return 'Program Özeti';
    }
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 1: return _buildStudentSelection();
      case 2: return _buildProgramTypeSelection();
      case 3: return _buildDateRangeSelection();
      case 4: return _buildSubjectSelection();
      case 5: return _buildMaterialSelection();
      case 6: return _buildTopicSelection();
      case 7: return _buildEtutSelection();
      case 8: return _buildDigitalEtutSelection();
      case 9: return _buildSummary();
      case 10: return _buildDistributionPreview();
      default: return Container();
    }
  }

  Widget _buildStudentSelection() {
    final stream = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').snapshots();
    return StreamBuilder<QuerySnapshot>(stream: stream, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Öğrenci bulunamadı.'));
      return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
        final student = snapshot.data!.docs[index];
        final data = student.data() as Map<String, dynamic>;
        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(leading: CircleAvatar(child: Text(data['name'][0])), title: Text('${data['name']} ${data['surname']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), subtitle: Text('No: ${data['number'] ?? 'N/A'}', style: GoogleFonts.poppins()), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onTap: () => setState(() { _selectedStudent = student; _currentStep = 2; })));
      });
    });
  }

  Widget _buildProgramTypeSelection() {
    final studentData = _selectedStudent!.data() as Map<String, dynamic>;
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [const SizedBox(height: 20), Text('Öğrenci: ${studentData['name']} ${studentData['surname']}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)), Text('için nasıl bir program oluşturmak istersiniz?', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700)), const SizedBox(height: 40)])),
      Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 32), title: Text('Sıfırdan Program Oluştur', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), subtitle: Text('Boş bir programla yeni bir başlangıç yapın.', style: GoogleFonts.poppins()), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => setState(() => _currentStep = 3))),
      const SizedBox(height: 16),
      Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Icon(Icons.edit_note, color: Colors.grey.shade600, size: 32), title: Text('Mevcut Programı Düzenle', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade700)), subtitle: Text('Öğrencinin son programını kopyalayın. (Yakında)', style: GoogleFonts.poppins()), trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400), onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu özellik yakında eklenecektir.'))); })),
    ]));
  }

  Widget _buildDateRangeSelection() {
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 16),
      Text('Program için bir başlangıç ve bitiş tarihi seçin.', style: GoogleFonts.poppins(fontSize: 18), textAlign: TextAlign.center), const SizedBox(height: 24),
      Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildDateDisplay('Başlangıç Tarihi', _selectedDateRange?.start), const SizedBox(height: 50, child: VerticalDivider(thickness: 1)), _buildDateDisplay('Bitiş Tarihi', _selectedDateRange?.end)]))),
      const SizedBox(height: 16),
      OutlinedButton.icon(icon: const Icon(Icons.date_range_outlined), label: Text('Tarih Aralığı Seç', style: GoogleFonts.poppins()), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _pickDateRange),
      const Spacer(),
      _buildStepNavigationBar(onNextPressed: _selectedDateRange == null ? null : () => setState(() => _currentStep = 4)),
    ]));
  }

  Widget _buildSubjectSelection() {
    final subjectsToList = _levelFilter == 'TYT' ? _tytSubjects : _aytSubjects;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16.0), child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'TYT', label: Text('TYT')), ButtonSegment(value: 'AYT', label: Text('AYT'))], selected: {_levelFilter}, onSelectionChanged: (selection) => setState(() => _levelFilter = selection.first))),
      Expanded(child: ListView.builder(itemCount: subjectsToList.length, itemBuilder: (context, index) {
        final subject = subjectsToList[index];
        final uniqueSubjectId = '$_levelFilter-$subject';
        final isSelected = _selectedSubjects.contains(uniqueSubjectId);
        return CheckboxListTile(title: Text(subject, style: GoogleFonts.poppins()), value: isSelected, onChanged: (bool? value) { setState(() { if (value == true) _selectedSubjects.add(uniqueSubjectId); else _selectedSubjects.remove(uniqueSubjectId); }); });
      })),
      _buildStepNavigationBar(onNextPressed: _selectedSubjects.isEmpty ? null : () => setState(() => _currentStep = 5)),
    ]);
  }

  Widget _buildMaterialSelection() {
    final cleanSubjectNames = _selectedSubjects.map((uniqueId) => uniqueId.split('-').last).toSet().toList();
    if (cleanSubjectNames.isEmpty) return const Center(child: Text('Lütfen önce ders seçin.'));
    final booksStream = FirebaseFirestore.instance.collection('books').where('subject', whereIn: cleanSubjectNames).snapshots();
    final practicesStream = FirebaseFirestore.instance.collection('practices').where('subject', whereIn: cleanSubjectNames).snapshots();
    final combinedStream = Rx.combineLatest2(booksStream, practicesStream, (QuerySnapshot books, QuerySnapshot practices) => [...books.docs, ...practices.docs]);
    return Column(children: [
      Expanded(child: StreamBuilder<List<DocumentSnapshot>>(
        stream: combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Seçilen derslere uygun materyal bulunamadı.', style: GoogleFonts.poppins()));
          final allMaterials = snapshot.data!;
          final filteredMaterials = allMaterials.where((doc) {
            final data = doc.data() as Map<String, dynamic>?; if (data == null) return false;
            final level = data['level'] as String?; final subject = data['subject'] as String?; if (level == null || subject == null) return false;
            return _selectedSubjects.contains('$level-$subject');
          }).toList();
          if (filteredMaterials.isEmpty) return Center(child: Text('Seçilen seviyeye uygun materyal bulunamadı.', style: GoogleFonts.poppins()));
          return ListView.builder(padding: const EdgeInsets.all(8.0), itemCount: _selectedSubjects.length, itemBuilder: (context, index) {
            final subjectUniqueId = _selectedSubjects[index];
            final level = subjectUniqueId.split('-').first;
            final subject = subjectUniqueId.split('-').last;
            final materialsForSubject = filteredMaterials.where((doc) { final data = doc.data() as Map<String, dynamic>; return data['subject'] == subject && data['level'] == level; }).toList();
            if (materialsForSubject.isEmpty) return const SizedBox.shrink();
            return Card(margin: const EdgeInsets.symmetric(vertical: 8.0), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(left: 8.0, bottom: 8.0), child: Text('$subjectUniqueId İçin Materyal Seçin', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
              ...materialsForSubject.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isBook = data.containsKey('bookType');
                if (isBook) {
                  final isSelected = _selectedBooksBySubject[subjectUniqueId]?.any((d) => d.id == doc.id) ?? false;
                  return CheckboxListTile(secondary: const Icon(Icons.menu_book, color: Colors.blueGrey), title: Text(data['publisher'], style: GoogleFonts.poppins()), subtitle: Text(data['bookType']), value: isSelected, onChanged: (bool? value) => _toggleBookSelection(subjectUniqueId, doc, value));
                } else {
                  final isSelected = _selectedPracticesBySubject[subjectUniqueId]?.any((d) => d.id == doc.id) ?? false;
                  return CheckboxListTile(secondary: const Icon(Icons.note_alt, color: Colors.teal), title: Text(data['publisher'], style: GoogleFonts.poppins()), subtitle: Text('Deneme (Adet: ${data['count']})'), value: isSelected, onChanged: (bool? value) => _togglePracticeSelection(subjectUniqueId, doc, value));
                }
              }).toList(),
            ])));
          });
        },
      )),
      _buildStepNavigationBar(onNextPressed: (_selectedBooksBySubject.values.every((list) => list.isEmpty) && _selectedPracticesBySubject.values.every((list) => list.isEmpty)) ? null : () {
        setState(() {
          if (_selectedBooksBySubject.values.every((list) => list.isEmpty)) {
            _currentStep = 7;
          } else {
            _currentStep = 6;
          }
        });
      }),
    ]);
  }

  Widget _buildTopicSelection() {
    return Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(8.0), itemCount: _selectedSubjects.length, itemBuilder: (context, subjectIndex) {
        final subjectUniqueId = _selectedSubjects[subjectIndex];
        final selectedBooks = _selectedBooksBySubject[subjectUniqueId] ?? [];
        if (selectedBooks.isEmpty) return const SizedBox.shrink();
        return Card(margin: const EdgeInsets.symmetric(vertical: 8.0), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 8.0, bottom: 4.0), child: Text(subjectUniqueId, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
          ...selectedBooks.map((bookDoc) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final topics = List<Map<String, dynamic>>.from(bookData['topics'] ?? []);
            return ExpansionTile(title: Text('${bookData['publisher']} - ${bookData['bookType']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), children: topics.map((topic) {
              final isSelected = _selectedTopicsByBook[subjectUniqueId]?[bookDoc.id]?.any((t) => t['konu'] == topic['konu']) ?? false;
              return CheckboxListTile(title: Text(topic['konu'] ?? ''), subtitle: Text('Sayfa: ${topic['sayfa'] ?? ''}'), value: isSelected, onChanged: (bool? value) {
                setState(() {
                  _selectedTopicsByBook.putIfAbsent(subjectUniqueId, () => {});
                  _selectedTopicsByBook[subjectUniqueId]!.putIfAbsent(bookDoc.id, () => []);
                  if (value == true) { if (!_selectedTopicsByBook[subjectUniqueId]![bookDoc.id]!.any((t) => t['konu'] == topic['konu'])) { _selectedTopicsByBook[subjectUniqueId]![bookDoc.id]!.add(topic); } }
                  else { _selectedTopicsByBook[subjectUniqueId]![bookDoc.id]!.removeWhere((t) => t['konu'] == topic['konu']); }
                });
              });
            }).toList());
          }).toList(),
        ])));
      })),
      _buildStepNavigationBar(onNextPressed: _selectedTopicsByBook.values.every((map) => map.values.every((list) => list.isEmpty)) ? null : () => setState(() => _currentStep = 7)),
    ]);
  }

  Widget _buildEtutSelection() {
    final allItems = _getAllSelectedItemsForEtut();
    final etutCounts = _calculateEtutCounts(_selectedDateRange);
    final totalAcademicSlots = etutCounts['academic']!;
    int totalEtutCount = _etutCounts.values.fold(0, (sum, count) => sum + count);

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Atanan Ödev Etütü: $totalEtutCount / $totalAcademicSlots', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: totalEtutCount == totalAcademicSlots ? Colors.green : Colors.black))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: allItems.length, itemBuilder: (context, index) {
        final item = allItems[index];
        final uniqueId = item['id'] as String;
        if (item['type'] == 'topic') {
          _endPageControllers.putIfAbsent(uniqueId, () => TextEditingController());
          return Card(margin: const EdgeInsets.symmetric(vertical: 6), child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item['subject'].split('-').last} / ${item['bookPublisher']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            Text(item['konu'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
            Row(children: [
              Text('Sayfa: ${item['sayfa']} - ', style: GoogleFonts.poppins()),
              SizedBox(width: 60, height: 40, child: TextFormField(controller: _endPageControllers[uniqueId], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Bitiş', contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),
              const Spacer(),
              DropdownButton<int>(value: _etutCounts[uniqueId] ?? 1, items: List.generate(10, (i) => i + 1).map((val) => DropdownMenuItem(value: val, child: Text('$val Etüt'))).toList(), onChanged: (val) => setState(() => _etutCounts[uniqueId] = val!)),
            ]),
          ])));
        } else {
          return Card(margin: const EdgeInsets.symmetric(vertical: 6), child: ListTile(
            title: Text('${item['subject'].split('-').last} / ${item['publisher']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            subtitle: Text('Deneme', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            trailing: DropdownButton<int>(value: _etutCounts[uniqueId] ?? 1, items: List.generate(10, (i) => i + 1).map((val) => DropdownMenuItem(value: val, child: Text('$val Etüt'))).toList(), onChanged: (val) => setState(() => _etutCounts[uniqueId] = val!)),
          ));
        }
      })),
      _buildStepNavigationBar(onNextPressed: totalEtutCount == totalAcademicSlots ? () => setState(() => _currentStep = 8) : null),
    ]);
  }

  Widget _buildDigitalEtutSelection() {
    final etutCounts = _calculateEtutCounts(_selectedDateRange);
    final totalDigitalSlots = etutCounts['digital']!;
    final filledCount = _digitalEtutControllers.sublist(0, totalDigitalSlots).where((c) => c.text.trim().isNotEmpty).length;

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Atanan Dijital Etüt: $filledCount / $totalDigitalSlots', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: filledCount == totalDigitalSlots ? Colors.green : Colors.black))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: totalDigitalSlots, itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: _digitalEtutControllers[index],
            decoration: InputDecoration(labelText: '${_getWeekdayNameForIndex(index)} Dijital Etüt Görevi', hintText: 'Örn: EBA Videoları, Test-3 Çözümleri', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
            onChanged: (text) => setState(() {}),
          ),
        );
      })),
      _buildStepNavigationBar(onNextPressed: filledCount == totalDigitalSlots ? () => setState(() => _currentStep = 9) : null),
    ]);
  }

  Widget _buildSummary() {
    final studentData = _selectedStudent!.data() as Map<String, dynamic>;
    final academicHomeworks = _getAllSelectedItemsForEtut();
    final etutCounts = _calculateEtutCounts(_selectedDateRange);
    final digitalHomeworks = _digitalEtutControllers.asMap().entries.where((entry) => entry.key < etutCounts['digital']!).map((entry) {
      return {'day': _getWeekdayNameForIndex(entry.key), 'task': entry.value.text};
    }).toList();

    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(16.0), children: [
        Text('Program Özeti', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        const SizedBox(height: 16),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [
          _buildSummaryItem(Icons.person_outline, 'Öğrenci', '${studentData['name']} ${studentData['surname']}'),
          _buildSummaryItem(Icons.date_range_outlined, 'Tarih Aralığı', '${DateFormat.yMMMMd('tr_TR').format(_selectedDateRange!.start)} - ${DateFormat.yMMMMd('tr_TR').format(_selectedDateRange!.end)}'),
        ]))),
        const SizedBox(height: 24),
        Text('Akademik Ödevler (${etutCounts['academic']} Etüt)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...academicHomeworks.map((item) => _buildHomeworkSummaryTile(item)),
        const SizedBox(height: 24),
        Text('Dijital Etütler (${etutCounts['digital']} Etüt)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...digitalHomeworks.map((item) => _buildDigitalSummaryTile(item)),
      ])),
      _buildStepNavigationBar(
        onNextPressed: _isSaving ? null : () {
          _generateAndSetInitialSchedule();
          setState(() => _currentStep = 10);
        },
        buttonText: 'Programı Önizle ve Dağıt',
        icon: Icons.shuffle,
      ),
    ]);
  }

  Widget _buildDistributionPreview() {
    if (_finalSchedule.isEmpty) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _currentPageIndex == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)),
        Text(DateFormat('d MMMM EEEE', 'tr_TR').format(_finalSchedule[_currentPageIndex].date), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _currentPageIndex == _finalSchedule.length - 1 ? null : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)),
      ])),
      Expanded(child: PageView.builder(
        controller: _pageController,
        itemCount: _finalSchedule.length,
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        itemBuilder: (context, dayIndex) {
          final day = _finalSchedule[dayIndex];
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: day.tasks.length,
            itemBuilder: (context, taskIndex) {
              final time = _getTimeForSlot(day.date, taskIndex);
              final task = day.tasks[taskIndex];
              final isSelectedForSwap = _isSwapMode && _firstSelectedItem?['dayIndex'] == dayIndex && _firstSelectedItem?['taskIndex'] == taskIndex;
              return GestureDetector(
                onDoubleTap: (task == null || task.data['type'] == 'fixed') ? null : () => _startSwap(dayIndex, taskIndex),
                onTap: () => _performSwap(dayIndex, taskIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelectedForSwap ? Colors.amber.shade700 : Colors.transparent, width: 3),
                  ),
                  child: _buildTaskTile(time, task),
                ),
              );
            },
          );
        },
      )),
      _buildStepNavigationBar(
        onNextPressed: _isSaving ? null : _saveProgram,
        buttonText: 'Onayla ve Programı Kaydet',
        icon: Icons.check_circle_outline,
      )
    ]);
  }

  void _generateAndSetInitialSchedule() {
    List<ScheduleTask> academicTasks = [];
    _getAllSelectedItemsForEtut().forEach((item) {
      final uniqueId = item['id'] as String;
      int etutCount = _etutCounts[uniqueId] ?? 1;

      var baseData = Map<String, dynamic>.from(item);
      final subjectUniqueId = baseData['subject'] as String;
      final subjectCleanName = subjectUniqueId.split('-').last;
      baseData['discipline'] = _subjectTypes[subjectCleanName];

      if (item['type'] == 'topic') {
        final endPageStr = _endPageControllers[uniqueId]?.text.trim() ?? '';
        final startPage = int.tryParse(item['sayfa'].toString());
        final endPage = int.tryParse(endPageStr);

        if (startPage != null && endPage != null && endPage > startPage && etutCount > 1) {
          final totalPages = endPage - startPage;
          final pagesPerEtut = (totalPages / etutCount).ceil();
          for (int i = 0; i < etutCount; i++) {
            final chunkStartPage = startPage + (i * pagesPerEtut);
            final chunkEndPage = min(chunkStartPage + pagesPerEtut, endPage);
            var chunkData = Map<String, dynamic>.from(baseData);
            chunkData['isChunked'] = true;
            chunkData['chunkIndex'] = i + 1;
            chunkData['chunkTotal'] = etutCount;
            chunkData['chunkPageRange'] = '$chunkStartPage-$chunkEndPage';
            academicTasks.add(ScheduleTask(data: chunkData));
          }
        } else {
          for (int i = 0; i < etutCount; i++) { academicTasks.add(ScheduleTask(data: baseData)); }
        }
      } else {
        for (int i = 0; i < etutCount; i++) { academicTasks.add(ScheduleTask(data: baseData)); }
      }
    });

    final Map<int, ScheduleTask> digitalTasksByWeekday = {};
    int digitalDayIndex = 0;
    for (int i = 0; i <= _selectedDateRange!.duration.inDays; i++) {
      final day = _selectedDateRange!.start.add(Duration(days: i));
      if (day.weekday != DateTime.sunday) {
        if(digitalDayIndex < _digitalEtutControllers.length){
          digitalTasksByWeekday[day.weekday] = ScheduleTask(data: {'type': 'digital', 'task': _digitalEtutControllers[digitalDayIndex].text});
          digitalDayIndex++;
        }
      }
    }

    List<ScheduleDay> newSchedule = [];
    final totalDays = _selectedDateRange!.duration.inDays + 1;
    for (int i = 0; i < totalDays; i++) {
      final currentDate = _selectedDateRange!.start.add(Duration(days: i));
      List<ScheduleTask?> dayTasks = [];
      if (currentDate.weekday == DateTime.sunday) {
        dayTasks.add(ScheduleTask(data: {'type': 'fixed', 'title': 'Genel Deneme'}));
      } else if (currentDate.weekday == DateTime.saturday) {
        dayTasks.add(ScheduleTask(data: {'type': 'fixed', 'title': 'TYT Denemesi'}));
        dayTasks.addAll(List.generate(5, (_) => null));
      } else {
        dayTasks.addAll(List.generate(10, (_) => null));
      }
      newSchedule.add(ScheduleDay(date: currentDate, tasks: dayTasks));
    }

    List<ScheduleTask> unplacedTasks = List.from(academicTasks);
    // Dijital görevleri öncelikli yerleştir
    for (var day in newSchedule) {
      if (digitalTasksByWeekday.containsKey(day.date.weekday)) {
        final firstEmptySlot = day.tasks.indexWhere((task) => task == null);
        if (firstEmptySlot != -1) {
          day.tasks[firstEmptySlot] = digitalTasksByWeekday[day.date.weekday];
        }
      }
    }

    // Akademik görevleri puanlayarak yerleştir
    for (int dayIndex = 0; dayIndex < newSchedule.length; dayIndex++) {
      final day = newSchedule[dayIndex];
      for (int taskIndex = 0; taskIndex < day.tasks.length; taskIndex++) {
        if (day.tasks[taskIndex] == null && unplacedTasks.isNotEmpty) {
          unplacedTasks.sort((a, b) {
            final scoreA = _calculatePlacementScore(a, newSchedule, dayIndex, taskIndex);
            final scoreB = _calculatePlacementScore(b, newSchedule, dayIndex, taskIndex);
            return scoreB.compareTo(scoreA); // En yüksek puanlı olanı başa al
          });

          final bestTask = unplacedTasks.first;
          day.tasks[taskIndex] = bestTask;
          unplacedTasks.remove(bestTask);
        }
      }
    }

    setState(() => _finalSchedule = newSchedule);
  }

  double _calculatePlacementScore(ScheduleTask task, List<ScheduleDay> schedule, int dayIndex, int taskIndex) {
    double score = 100.0;
    final taskData = task.data;
    if (taskData['subject'] == null) return score + Random().nextDouble();

    final taskSubjectUniqueId = taskData['subject'] as String;
    final taskSubject = taskSubjectUniqueId.split('-').last;
    final taskDiscipline = _subjectTypes[taskSubject];

    if (taskData['isChunked'] == true && taskData['chunkIndex'] > 1) {
      bool previousPartPlaced = false;
      for (int d = 0; d < schedule.length; d++) {
        for (int t = 0; t < schedule[d].tasks.length; t++) {
          final existingTask = schedule[d].tasks[t];
          if (d < dayIndex || (d == dayIndex && t < taskIndex)) {
            if (existingTask != null && existingTask.data['isChunked'] == true && existingTask.data['konu'] == taskData['konu'] && existingTask.data['chunkIndex'] == taskData['chunkIndex'] - 1) {
              previousPartPlaced = true;
              break;
            }
          }
        }
        if (previousPartPlaced) break;
      }
      if (!previousPartPlaced) return -double.infinity;
    }

    ScheduleTask? previousTask;
    if (taskIndex > 0) {
      previousTask = schedule[dayIndex].tasks[taskIndex - 1];
    } else if (dayIndex > 0) {
      previousTask = schedule[dayIndex - 1].tasks.lastWhere((t) => t != null, orElse: () => null);
    }

    if (previousTask != null && (previousTask.data['type'] == 'topic' || previousTask.data['type'] == 'practice')) {
      final prevData = previousTask.data;
      final prevSubjectRaw = prevData['subject'] as String?;
      if (prevSubjectRaw != null) {
        final prevSubject = prevSubjectRaw.split('-').last;
        final prevDiscipline = _subjectTypes[prevSubject];
        if (taskData['isChunked'] == true && prevData['isChunked'] == true && prevData['konu'] == taskData['konu']) { score -= 80; }
        if (prevDiscipline == taskDiscipline) { score -= 30; }
        if (prevSubjectRaw == taskSubjectUniqueId) { score -= 20; }
        if (prevData['bookPublisher'] != null && prevData['bookPublisher'] == taskData['bookPublisher']) { score -= 10; }
      }
    }

    return score + Random().nextDouble();
  }

  Future<void> _saveProgram() async {
    setState(() => _isSaving = true);
    try {
      Map<String, List<Map<String, dynamic>>> dailySlots = {};
      for (var day in _finalSchedule) {
        final dateString = DateFormat('yyyy-MM-dd').format(day.date);
        List<Map<String, dynamic>> tasksForDay = [];
        for (int i = 0; i < day.tasks.length; i++) {
          final time = _getTimeForSlot(day.date, i);
          final task = day.tasks[i];
          tasksForDay.add({
            'time': time.replaceAll('\n', ' - '),
            'task': task?.data ?? {'type': 'empty'}
          });
        }
        dailySlots[dateString] = tasksForDay;
      }
      await FirebaseFirestore.instance.collection('schedules').add({
        'studentUid': _selectedStudent!.id,
        'startDate': _selectedDateRange!.start,
        'endDate': _selectedDateRange!.end,
        'createdAt': FieldValue.serverTimestamp(),
        'dailySlots': dailySlots,
        'status': 'active',
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program başarıyla oluşturuldu!'), backgroundColor: Colors.green));
        setState(() { _currentStep = 1; _selectedStudent = null; _selectedDateRange = null; _levelFilter = 'TYT'; _selectedSubjects.clear(); _selectedBooksBySubject.clear(); _selectedPracticesBySubject.clear(); _selectedTopicsByBook.clear(); _etutCounts.clear(); _endPageControllers.clear(); _digitalEtutControllers.forEach((c) => c.clear()); _isSaving = false; });
      }
    } catch(e) {
      if(mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _startSwap(int dayIndex, int taskIndex) {
    setState(() {
      _isSwapMode = true;
      _firstSelectedItem = {'dayIndex': dayIndex, 'taskIndex': taskIndex};
    });
  }

  void _performSwap(int dayIndexB, int taskIndexB) {
    if (!_isSwapMode || _firstSelectedItem == null) return;
    final dayIndexA = _firstSelectedItem!['dayIndex']!;
    final taskIndexA = _firstSelectedItem!['taskIndex']!;
    if (dayIndexA == dayIndexB && taskIndexA == taskIndexB) {
      _cancelSwap();
      return;
    }
    setState(() {
      final taskA = _finalSchedule[dayIndexA].tasks[taskIndexA];
      final taskB = _finalSchedule[dayIndexB].tasks[taskIndexB];
      if(taskA?.data['type'] == 'fixed' || taskB?.data['type'] == 'fixed') return;

      _finalSchedule[dayIndexA].tasks[taskIndexA] = taskB;
      _finalSchedule[dayIndexB].tasks[taskIndexB] = taskA;
      _cancelSwap();
    });
  }

  void _cancelSwap() {
    setState(() {
      _isSwapMode = false;
      _firstSelectedItem = null;
    });
  }

  Map<String, int> _calculateEtutCounts(DateTimeRange? range) {
    if (range == null) return {'academic': 0, 'digital': 0};
    int academic = 0;
    int digital = 0;
    for (int i = 0; i <= range.duration.inDays; i++) {
      final day = range.start.add(Duration(days: i));
      if (day.weekday == DateTime.saturday) {
        academic += 4;
        digital += 1;
      } else if (day.weekday != DateTime.sunday) {
        academic += 9;
        digital += 1;
      }
    }
    return {'academic': academic, 'digital': digital};
  }

  String _getWeekdayNameForIndex(int index) {
    if (_selectedDateRange == null) return '';
    final validDays = <String>[];
    for (int i = 0; i <= _selectedDateRange!.duration.inDays; i++) {
      final day = _selectedDateRange!.start.add(Duration(days: i));
      if (day.weekday != DateTime.sunday) {
        validDays.add(_daysOfWeek[day.weekday - 1]);
      }
    }
    if (index >= validDays.length) return '';
    return validDays[index];
  }

  Widget _buildTaskTile(String time, ScheduleTask? task) {
    if (task == null) return _buildEmptyTaskTile(time);
    if (task.data['type'] == 'fixed') return _buildFixedTaskTile(time, task.data['title']);
    final bool isDigital = task.data['type'] == 'digital';
    String title = isDigital ? 'Dijital Etüt' : '${(task.data['subject'] as String).split('-').last}: ${task.data['publisher'] ?? task.data['bookPublisher']}';

    String subtitle;
    if(task.data['isChunked'] == true) {
      subtitle = '${task.data['konu']} (Sayfa: ${task.data['chunkPageRange']})';
    } else {
      subtitle = isDigital ? task.data['task'] : '${task.data['konu'] ?? 'Deneme'}';
    }

    return Card(elevation: 2, child: ListTile(
      leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(time.split('\n')[0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(time.split('\n')[1], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
      ]),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
    ));
  }

  Widget _buildEmptyTaskTile(String time) {
    return Card(elevation: 0, color: Colors.grey.shade200, child: ListTile(
      leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(time.split('\n')[0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(time.split('\n')[1], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
      ]),
      title: Text('Boş Etüt', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
    ));
  }

  Widget _buildFixedTaskTile(String time, String title) {
    return Card(color: Colors.grey.shade300, elevation: 1, child: ListTile(
      leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(time, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))]),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
    ));
  }

  void _toggleBookSelection(String subjectUniqueId, DocumentSnapshot doc, bool? value) { setState(() { _selectedBooksBySubject.putIfAbsent(subjectUniqueId, () => []); if (value == true) { if (!_selectedBooksBySubject[subjectUniqueId]!.any((d) => d.id == doc.id)) { _selectedBooksBySubject[subjectUniqueId]!.add(doc); } } else { _selectedBooksBySubject[subjectUniqueId]!.removeWhere((d) => d.id == doc.id); } }); }
  void _togglePracticeSelection(String subjectUniqueId, DocumentSnapshot doc, bool? value) { setState(() { _selectedPracticesBySubject.putIfAbsent(subjectUniqueId, () => []); if (value == true) { if (!_selectedPracticesBySubject[subjectUniqueId]!.any((d) => d.id == doc.id)) { _selectedPracticesBySubject[subjectUniqueId]!.add(doc); } } else { _selectedPracticesBySubject[subjectUniqueId]!.removeWhere((d) => d.id == doc.id); } }); }

  List<Map<String, dynamic>> _getAllSelectedItemsForEtut() {
    final List<Map<String, dynamic>> allItems = [];
    _selectedTopicsByBook.forEach((subjectUniqueId, books) {
      books.forEach((bookId, topics) {
        DocumentSnapshot? bookDoc = _selectedBooksBySubject[subjectUniqueId]?.firstWhere((doc) => doc.id == bookId, orElse: () => null as DocumentSnapshot);
        if (bookDoc == null) return;
        final bookData = bookDoc.data() as Map<String, dynamic>;
        for (var topic in topics) { allItems.add({'type': 'topic', 'id': '$subjectUniqueId-$bookId-${topic['konu']}', 'subject': subjectUniqueId, 'bookPublisher': bookData['publisher'], 'bookType': bookData['bookType'], 'konu': topic['konu'], 'sayfa': topic['sayfa']}); }
      });
    });
    _selectedPracticesBySubject.forEach((subjectUniqueId, practices) {
      for (var practiceDoc in practices) {
        final practiceData = practiceDoc.data() as Map<String, dynamic>;
        allItems.add({'type': 'practice', 'id': '$subjectUniqueId-${practiceDoc.id}', 'subject': subjectUniqueId, 'publisher': practiceData['publisher']});
      }
    });
    return allItems;
  }

  String _getTimeForSlot(DateTime date, int slotIndex) {
    if (date.weekday == DateTime.sunday) return "Tüm Gün";
    final tasksOnDay = _finalSchedule.firstWhere((day) => day.date.year == date.year && day.date.month == date.month && day.date.day == date.day).tasks;
    final fixedTasksCount = tasksOnDay.where((task) => task?.data['type'] == 'fixed').length;

    if (date.weekday == DateTime.saturday) {
      if (slotIndex < fixedTasksCount) return "09:00\n12:10";
      return _saturdayTimes[slotIndex - fixedTasksCount];
    }

    if (slotIndex < _weekdayTimes.length) {
      return _weekdayTimes[slotIndex];
    }
    return "";
  }

  Widget _buildStepNavigationBar({required VoidCallback? onNextPressed, String buttonText = 'Devam Et', IconData icon = Icons.arrow_forward_ios}) { return Padding(padding: const EdgeInsets.all(16.0), child: ElevatedButton.icon(style: _getPrimaryButtonStyle(fullWidth: true), onPressed: onNextPressed, icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(icon, size: 16), label: Text(buttonText, style: GoogleFonts.poppins(fontSize: 16)))); }
  ButtonStyle _getPrimaryButtonStyle({bool fullWidth = false}) { return ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, minimumSize: fullWidth ? const Size.fromHeight(50) : null, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))); }
  Future<void> _pickDateRange() async { final now = DateTime.now(); final DateTimeRange? picked = await showDateRangePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365))); if (picked != null) setState(() => _selectedDateRange = picked); }
  Widget _buildDateDisplay(String label, DateTime? date) { return Column(children: [ Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade600)), const SizedBox(height: 8), Text(date != null ? DateFormat.yMMMMd('tr_TR').format(date) : '-- / -- / ----', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))]); }

  Widget _buildHomeworkSummaryTile(Map<String, dynamic> item) {
    final uniqueId = item['id'] as String;
    final etutCount = _etutCounts[uniqueId] ?? 1;
    final endPage = _endPageControllers[uniqueId]?.text.trim() ?? '';
    final pageInfo = item['type'] == 'topic' ? 'Sayfa: ${item['sayfa']}${endPage.isNotEmpty ? ' - $endPage' : ''}' : 'Deneme';
    return Card(elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(
      title: Text('${(item['subject'] as String).split('-').last}: ${item['publisher']}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text('${item['konu'] ?? 'Deneme'} ($pageInfo)', style: GoogleFonts.poppins(fontSize: 12)),
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text('$etutCount Etüt', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      ),
    ));
  }

  Widget _buildDigitalSummaryTile(Map<String, dynamic> item) {
    return Card(elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(
      leading: const Icon(Icons.laptop_chromebook_outlined, color: Colors.teal),
      title: Text('${item['day']} Dijital Etüt', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(item['task'], style: GoogleFonts.poppins(fontSize: 12)),
    ));
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [
      Icon(icon, color: Theme.of(context).primaryColor), const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ]),
    ]));
  }
}