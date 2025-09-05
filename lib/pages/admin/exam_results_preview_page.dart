import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/exam_result.dart';

class ExamResultsPreviewPage extends StatelessWidget {
  final List<StudentExamResult> results;
  final String examName;

  const ExamResultsPreviewPage({
    super.key,
    required this.results,
    required this.examName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Önizleme', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(examName, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return StudentResultCard(result: result);
        },
      ),
    );
  }
}

class StudentResultCard extends StatelessWidget {
  final StudentExamResult result;
  const StudentResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            result.overallRank.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(result.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'No: ${result.studentNumber} | Toplam Net: ${result.totalNet.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildSummaryRow(),
                const Divider(height: 20),
                _buildLessonsTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn("Puan", result.score.toStringAsFixed(3), Colors.blue),
        _buildStatColumn("Sınıf S.", result.classRank.toString(), Colors.orange),
        _buildStatColumn("Doğru", result.totalCorrect.toStringAsFixed(0), Colors.green),
        _buildStatColumn("Yanlış", result.totalWrong.toStringAsFixed(0), Colors.red),
      ],
    );
  }

  Widget _buildLessonsTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        _buildHeaderRow(),
        ...result.lessonResults.map((lesson) => _buildLessonRow(lesson)).toList(),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: ["Ders", "Doğru", "Yanlış", "Net"]
          .map((label) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ))
          .toList(),
    );
  }

  TableRow _buildLessonRow(LessonResult lesson) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(lesson.lessonName, style: GoogleFonts.poppins(fontSize: 12))),
        Text(lesson.correct.toStringAsFixed(0), textAlign: TextAlign.center),
        Text(lesson.wrong.toStringAsFixed(0), textAlign: TextAlign.center),
        Text(lesson.net.toStringAsFixed(2), style: GoogleFonts.poppins(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ],
    );
  }
}