import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamResultsPreviewPage extends StatelessWidget {
  final String markdownContent;
  final String examName;

  const ExamResultsPreviewPage({
    super.key,
    required this.markdownContent,
    required this.examName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          examName,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
      // --- YENİ SİSTEM: Yatayda da kaydırılabilen alan ---
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Bu sayede tablo sağa sola kaydırılabilir
          padding: const EdgeInsets.all(16.0),
          child: MarkdownBody(
            data: markdownContent,
            // Hata vermeyecek, en stabil ve temel stil tanımlaması
            styleSheet: MarkdownStyleSheet(
              tableHead: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              p: GoogleFonts.poppins(fontSize: 13), // Yazıyı biraz küçülttük
              tableBorder: TableBorder.all(color: Colors.grey.shade400, width: 1),
              tableCellsPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            ),
          ),
        ),
      ),
    );
  }
}