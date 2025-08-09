import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/program_generator_page.dart';

class SetEffortPage extends StatefulWidget {
  // Önceki sayfalardan gelen tüm verileri alıyoruz
  final List<Map<String, dynamic>> selectedSubjects;
  final Map<String, List<String>> assignedBooks;
  final Map<String, String> startingTopics;

  const SetEffortPage({
    super.key,
    required this.selectedSubjects,
    required this.assignedBooks,
    required this.startingTopics,
  });

  @override
  State<SetEffortPage> createState() => _SetEffortPageState();
}

class _SetEffortPageState extends State<SetEffortPage> {
  // Seçilen yıldız sayısını (efor seviyesini) tutar
  int _effortLevel = 3; // Varsayılan olarak 3 yıldız seçili gelsin

  // Yıldız sayısına göre açıklayıcı metin döndüren fonksiyon
  String _getEffortLevelText() {
    switch (_effortLevel) {
      case 1:
        return 'Hafif Tekrar Temposu';
      case 2:
        return 'Normal Tempo';
      case 3:
        return 'Standart Ödevlendirme';
      case 4:
        return 'Yoğun Tempo';
      case 5:
        return 'Sınav Hazırlık Temposu';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Efor Seviyesi Belirle', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // Sayfa içeriğini dikeyde ortalayıp yayıyoruz
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Text(
                  'Öğrencinin yıldızı ne kadar parlasın?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                // 5 yıldızlı rating bar'ı oluşturan Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _effortLevel ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _effortLevel = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Seçilen yıldıza göre çıkan açıklama metni
                Text(
                  _getEffortLevelText(),
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),

            // Program Oluştur butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green.shade600,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ProgramGeneratorPage(
                      selectedSubjects: widget.selectedSubjects,
                      assignedBooks: widget.assignedBooks,
                      startingTopics: widget.startingTopics,
                      effortLevel: _effortLevel,
                    )
                ));
              },
              child: Text('Program Oluştur', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}