import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/set_effort_page.dart';

class SelectTopicsPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubjectsWithBooks;
  final Map<String, List<String>> assignedBooks;

  const SelectTopicsPage({
    super.key,
    required this.selectedSubjectsWithBooks,
    required this.assignedBooks,
  });

  @override
  State<SelectTopicsPage> createState() => _SelectTopicsPageState();
}

class _SelectTopicsPageState extends State<SelectTopicsPage> {
  // Key: 'TYT-Matematik_Kitap Adı', Value: 'Seçilen başlangıç konusu'
  final Map<String, String> _startingTopicSelections = {};

  // TODO: Bu konu listeleri, kitaba göre Firestore'dan çekilecek. Şimdilik sahte veri.
  final Map<String, List<String>> _mockBookTopics = {
    '3D TYT Matematik Soru Bankası': ['Temel Kavramlar', 'Sayı Basamakları', 'Bölünebilme', 'Rasyonel Sayılar', 'Üslü Sayılar'],
    'Bilgi Sarmal TYT Türkçe Soru Bankası': ['Sözcükte Anlam', 'Cümlede Anlam', 'Paragraf', 'Yazım Kuralları', 'Noktalama İşaretleri'],
    'Orijinal AYT Matematik': ['Polinomlar', 'Trigonometri', 'Logaritma', 'Diziler', 'Limit ve Süreklilik', 'Türev', 'İntegral'],
    'Palme TYT Biyoloji Konu Anlatımı': ['Canlıların Ortak Özellikleri', 'Hücre ve Organelleri', 'Sınıflandırma', 'Kalıtım'],
    'Limit Edebiyat El Kitabı': ['Şiir Bilgisi', 'İslamiyet Öncesi Türk Edebiyatı', 'Divan Edebiyatı', 'Tanzimat Edebiyatı'],
    '345 TYT Fizik Denemeleri': ['Fizik Bilimine Giriş', 'Madde ve Özellikleri', 'Kuvvet ve Hareket', 'İş, Güç, Enerji', 'Isı ve Sıcaklık']
  };

  void _showTopicSelectionDialog(String subjectBookKey, String bookName) {
    final topics = _mockBookTopics[bookName] ?? [];
    if (topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu kitap için konu listesi bulunamadı.')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$bookName Konuları'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return RadioListTile<String>(
                  title: Text(topic),
                  value: topic,
                  groupValue: _startingTopicSelections[subjectBookKey],
                  onChanged: (String? value) {
                    setState(() {
                      _startingTopicSelections[subjectBookKey] = value!;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Başlangıç Konusu Seç', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedSubjectsWithBooks.length,
              itemBuilder: (context, index) {
                final subjectData = widget.selectedSubjectsWithBooks[index];
                final subjectName = subjectData['subject'];
                final subjectType = subjectData['type'];
                final subjectKey = '$subjectType-$subjectName';
                final assignedBooksForSubject = widget.assignedBooks[subjectKey]!;

                if (assignedBooksForSubject.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: assignedBooksForSubject.map((bookName) {
                    final subjectBookKey = '$subjectKey-$bookName';
                    final selectedTopic = _startingTopicSelections[subjectBookKey] ?? 'Başlangıç konusu seçmek için tıklayın';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(bookName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text('$subjectType - $subjectName\nBaşlangıç: $selectedTopic', style: TextStyle(color: selectedTopic.startsWith('Başlangıç') ? Colors.red.shade400 : Colors.black87)),
                        isThreeLine: true,
                        trailing: const Icon(Icons.edit_note),
                        onTap: () => _showTopicSelectionDialog(subjectBookKey, bookName),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 4,
                side: BorderSide(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => SetEffortPage(
                      selectedSubjects: widget.selectedSubjectsWithBooks,
                      assignedBooks: widget.assignedBooks,
                      startingTopics: _startingTopicSelections,
                    )
                ));
              },
              child: Text('İlerle', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}