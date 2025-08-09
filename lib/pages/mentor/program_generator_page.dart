import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// Sayfaya özel veri modelleri
class HomeworkTask {
  final String id;
  final String subject;
  final String type; // TYT/AYT
  final String book;
  final String topic;
  final String pageRange;
  HomeworkTask({required this.id, required this.subject, required this.type, required this.book, required this.topic, required this.pageRange});
}

class ScheduleSlot {
  final String timeRange;
  final String duration;
  HomeworkTask? task; // Bu slota atanmış görev (boş olabilir)
  ScheduleSlot({required this.timeRange, required this.duration, this.task});
}

class ProgramGeneratorPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubjects;
  final Map<String, List<String>> assignedBooks;
  final Map<String, String> startingTopics;
  final int effortLevel;

  const ProgramGeneratorPage({
    super.key,
    required this.selectedSubjects,
    required this.assignedBooks,
    required this.startingTopics,
    required this.effortLevel,
  });

  @override
  State<ProgramGeneratorPage> createState() => _ProgramGeneratorPageState();
}

class _ProgramGeneratorPageState extends State<ProgramGeneratorPage> {
  late PageController _pageController;
  DateTime _currentDate = DateTime.now();

  // Tüm haftanın programını tutan ana veri yapısı
  Map<int, List<ScheduleSlot>> _weeklySchedule = {};

  // Takas için seçilen görevi tutan state
  ({int day, int slotIndex})? _selectedForSwap;

  // Örnek etüt saatleri (yolladığın dosyadan)
  final List<Map<String, String>> _timeSlotsData = [
    {"range": "08:30 - 09:10", "duration": "40 dk"}, {"range": "09:20 - 10:00", "duration": "40 dk"},
    {"range": "10:10 - 10:50", "duration": "40 dk"}, {"range": "11:00 - 11:40", "duration": "40 dk"},
    // ... Diğer etüt saatleri buraya eklenebilir
  ];

  // TODO: Bu da Firestore'dan gelecek, şimdilik sahte veri
  final Map<String, List<String>> _mockBookTopics = {
    '3D TYT Matematik Soru Bankası': ['Temel Kavramlar', 'Sayı Basamakları', 'Bölünebilme', 'Rasyonel Sayılar', 'Üslü Sayılar', 'Köklü Sayılar', 'Çarpanlara Ayırma'],
    // ... Diğer kitapların konuları
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentDate.weekday - 1);
    _generateInitialProgram();
  }

  void _generateInitialProgram() {
    List<HomeworkTask> allTasks = [];
    int taskCounter = 0;

    widget.selectedSubjects.forEach((subjectData) {
      final subjectKey = '${subjectData['type']}-${subjectData['subject']}';
      final assignedBooks = widget.assignedBooks[subjectKey] ?? [];

      for (var book in assignedBooks) {
        final topicKey = '$subjectKey-$book';
        final startTopic = widget.startingTopics[topicKey];
        final allTopics = _mockBookTopics[book] ?? [];

        int startTopicIndex = allTopics.indexOf(startTopic!);
        if (startTopicIndex == -1) continue;

        // Başlangıç sayfasını ve sayfa başına çözülecek soru sayısını varsayalım
        int currentPage = 34; // Örnek başlangıç sayfası
        int pagesPerEtut = widget.effortLevel; // Yıldız sayısı = sayfa sayısı

        for (int i = 0; i < subjectData['etut']; i++) {
          int currentTopicIndex = startTopicIndex + i;
          String currentTopic = (currentTopicIndex < allTopics.length)
              ? allTopics[currentTopicIndex]
              : "${allTopics.last} (Tekrar)";

          allTasks.add(HomeworkTask(
            id: 'task_${taskCounter++}',
            subject: subjectData['subject'],
            type: subjectData['type'],
            book: book,
            topic: currentTopic,
            pageRange: '${currentPage} - ${currentPage + pagesPerEtut - 1}',
          ));
          currentPage += pagesPerEtut;
        }
      }
    });

    allTasks.shuffle(Random());

    // Haftanın 7 gününü boş slotlarla doldur
    for (int i = 1; i <= 7; i++) {
      _weeklySchedule[i] = _timeSlotsData.map((slot) =>
          ScheduleSlot(timeRange: slot['range']!, duration: slot['duration']!)
      ).toList();
    }

    // Karıştırılmış görevleri boş slotlara ata
    int taskIndex = 0;
    for (int day = 1; day <= 7; day++) {
      for (int slot = 0; slot < _weeklySchedule[day]!.length; slot++) {
        if (taskIndex < allTasks.length) {
          _weeklySchedule[day]![slot].task = allTasks[taskIndex++];
        } else {
          break;
        }
      }
      if (taskIndex >= allTasks.length) break;
    }

    setState(() {});
  }

  void _handleSwap(int targetDay, int targetSlotIndex) {
    if (_selectedForSwap == null) return; // Takas için bir şey seçilmemişse çık

    final sourceDay = _selectedForSwap!.day;
    final sourceSlotIndex = _selectedForSwap!.slotIndex;

    // Görevleri yer değiştir
    final sourceTask = _weeklySchedule[sourceDay]![sourceSlotIndex].task;
    final targetTask = _weeklySchedule[targetDay]![targetSlotIndex].task;

    setState(() {
      _weeklySchedule[sourceDay]![sourceSlotIndex].task = targetTask;
      _weeklySchedule[targetDay]![targetSlotIndex].task = sourceTask;
      _selectedForSwap = null; // Seçimi temizle
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Program Oluşturucu', style: GoogleFonts.poppins()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                  },
                ),
                Text(
                  DateFormat('d MMMM EEEE', 'tr_TR').format(_currentDate),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentDate = DateTime.now().add(Duration(days: index - (DateTime.now().weekday - 1)));
          });
        },
        itemBuilder: (context, index) {
          final dayOfWeek = index + 1;
          final slots = _weeklySchedule[dayOfWeek] ?? [];
          return ListView.builder(
            itemCount: slots.length,
            itemBuilder: (context, slotIndex) {
              final slot = slots[slotIndex];
              bool isSelectedForSwap = _selectedForSwap?.day == dayOfWeek && _selectedForSwap?.slotIndex == slotIndex;
              return _buildScheduleTile(slot, dayOfWeek, slotIndex, isSelectedForSwap);
            },
          );
        },
        itemCount: 7, // Haftanın 7 günü
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleSlot slot, int day, int slotIndex, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Sol Taraf: Saat ve Süre
          Container(
            padding: const EdgeInsets.all(12),
            width: 90,
            child: Column(
              children: [
                Text(slot.timeRange, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(slot.duration, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Sağ Taraf: Görev Bilgisi ve Butonlar
          Expanded(
            child: slot.task == null
                ? const Center(child: Text("Boş Etüt", style: TextStyle(color: Colors.grey)))
                : InkWell(
              onTap: () {
                if (_selectedForSwap != null) {
                  _handleSwap(day, slotIndex);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${slot.task!.type} ${slot.task!.subject}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          Text(slot.task!.book, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          Text('Konu: ${slot.task!.topic}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          Text('Sayfalar: ${slot.task!.pageRange}', style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                    // Takas ve Edit Butonları
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, color: Colors.blueAccent),
                          tooltip: 'Takas Etmek için Seç',
                          onPressed: () {
                            setState(() {
                              _selectedForSwap = (day: day, slotIndex: slotIndex);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                          tooltip: 'Düzenle',
                          onPressed: () { /* TODO: Editleme fonksiyonu */ },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}