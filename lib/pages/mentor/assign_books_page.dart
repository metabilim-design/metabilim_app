import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/select_topics_page.dart';

class AssignBooksPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubjects;

  const AssignBooksPage({super.key, required this.selectedSubjects});

  @override
  State<AssignBooksPage> createState() => _AssignBooksPageState();
}

class _AssignBooksPageState extends State<AssignBooksPage> {
  final Map<String, List<String>> _assignedBooks = {};

  final List<String> _allAvailableBooks = [
    '3D TYT Matematik Soru Bankası',
    'Bilgi Sarmal TYT Türkçe Soru Bankası',
    'Orijinal AYT Matematik',
    'Palme TYT Biyoloji Konu Anlatımı',
    'Limit Edebiyat El Kitabı',
    '345 TYT Fizik Denemeleri'
  ];

  @override
  void initState() {
    super.initState();
    for (var subjectData in widget.selectedSubjects) {
      final key = '${subjectData['type']}-${subjectData['subject']}';
      _assignedBooks[key] = [];
    }
  }

  void _showBookSelectionDialog(String subjectKey) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Kitap Seç'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allAvailableBooks.length,
                  itemBuilder: (context, index) {
                    final book = _allAvailableBooks[index];
                    final isSelected = _assignedBooks[subjectKey]?.contains(book) ?? false;
                    return CheckboxListTile(
                      title: Text(book),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _assignedBooks[subjectKey]!.add(book);
                          } else {
                            _assignedBooks[subjectKey]!.remove(book);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                    child: const Text('Tamam'),
                    onPressed: () => Navigator.of(context).pop()
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kaynak Atama', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedSubjects.length,
              itemBuilder: (context, index) {
                final subjectData = widget.selectedSubjects[index];
                final subjectName = subjectData['subject'];
                final subjectType = subjectData['type'];
                final subjectKey = '$subjectType-$subjectName';
                final booksForThisSubject = _assignedBooks[subjectKey]!;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subjectName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(subjectType, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: booksForThisSubject.length + 1,
                              itemBuilder: (context, bookIndex) {
                                if (bookIndex == booksForThisSubject.length) {
                                  return GestureDetector(
                                    onTap: () => _showBookSelectionDialog(subjectKey),
                                    child: Container(
                                      width: 50,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                        // HATA DÜZELTMESİ: BorderStyle.dashed, BorderStyle.solid olarak değiştirildi.
                                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.grey),
                                    ),
                                  );
                                }
                                final book = booksForThisSubject[bookIndex];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Chip(
                                    label: Text(book),
                                    onDeleted: () {
                                      setState(() {
                                        _assignedBooks[subjectKey]!.remove(book);
                                      });
                                    },
                                    deleteIconColor: Colors.red.shade400,
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => SelectTopicsPage(
                      selectedSubjectsWithBooks: widget.selectedSubjects,
                      assignedBooks: _assignedBooks,
                    )
                ));
              },
              child: Text('İleri', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}