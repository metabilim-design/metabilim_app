import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/pages/admin/exam_results_preview_page.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExamAnalysisPage extends StatefulWidget {
  const ExamAnalysisPage({super.key});

  @override
  State<ExamAnalysisPage> createState() => _ExamAnalysisPageState();
}

class _ExamAnalysisPageState extends State<ExamAnalysisPage> {
  bool _isProcessing = false;
  String _processingStatus = "";
  PlatformFile? _pickedFile;

  void _showErrorDialog(String message) {
    final displayMessage = message.startsWith("Exception: ") ? message.substring(11) : message;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Bir Sorun Oluştu", style: GoogleFonts.poppins()),
        content: Text(displayMessage, style: GoogleFonts.poppins()),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tamam'))],
      ),
    );
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) setState(() => _pickedFile = result.files.single);
  }

  Future<void> startAnalysis() async {
    if (_pickedFile?.bytes == null) {
      _showErrorDialog("Lütfen önce bir PDF dosyası seçin.");
      return;
    }
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      updateStatus("1/3: PDF'ten metinler çıkarılıyor...");
      final pdfText = await _extractTextFromPdf(_pickedFile!.bytes!);

      updateStatus("2/3: Yapay zeka ham veriyi işliyor...");
      final plainTextData = await _extractDataAsPlainText(pdfText);

      updateStatus("3/3: Veri doğrulanıyor ve arayüz hazırlanıyor...");
      final jsonString = await _convertPlainTextToJson(plainTextData);

      final results = _parseResults(jsonString);

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ExamResultsPreviewPage(
            results: results,
            examName: _pickedFile!.name,
          ),
        ));
      }
    } catch (e) {
      debugPrint("Analiz sırasında hata oluştu: ${e.toString()}");
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String> _extractTextFromPdf(Uint8List pdfBytes) async {
    final document = PdfDocument(inputBytes: pdfBytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    if (text.trim().isEmpty) throw Exception("PDF dosyasından metin okunamadı.");
    return text;
  }

  GenerativeModel _getGenerativeModel({String? responseMimeType}) {
    // Artık dotenv.load() yok, doğrudan anahtarı kullanıyoruz.
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('GEMINI_API_KEY .env dosyasında bulunamadı veya main.dart içinde yüklenmedi.');

    return GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      generationConfig: GenerationConfig(responseMimeType: responseMimeType),
    );
  }

  Future<String> _extractDataAsPlainText(String pdfText) async {
    final model = _getGenerativeModel();
    final prompt = _createPlainTextPrompt(pdfText);

    final response = await model.generateContent([Content.text(prompt)]);
    final plainText = response.text;

    if (plainText == null || plainText.trim().isEmpty) {
      throw Exception("Yapay zeka PDF içeriğinden veri çıkaramadı.");
    }
    debugPrint("--- HAM VERİ ÇIKTISI ---\n$plainText");
    return plainText;
  }

  Future<String> _convertPlainTextToJson(String plainTextData) async {
    final model = _getGenerativeModel(responseMimeType: "application/json");
    final prompt = _createJsonFromPlainTextPrompt(plainTextData);

    final response = await model.generateContent([Content.text(prompt)]);
    final jsonString = response.text;

    if (jsonString == null || jsonString.trim().isEmpty) {
      throw Exception("Yapay zeka, işlenen veriyi JSON formatına dönüştüremedi.");
    }
    debugPrint("--- JSON ÇIKTISI ---\n$jsonString");
    return jsonString;
  }

  List<StudentExamResult> _parseResults(String jsonString) {
    try {
      final List<dynamic> parsedData = jsonDecode(jsonString);
      return parsedData.map((data) => StudentExamResult.fromJson(data)).toList();
    } on FormatException {
      throw Exception("Son veri doğrulama adımı başarısız oldu. Lütfen tekrar deneyin.");
    }
  }

  void updateStatus(String status) => setState(() => _processingStatus = status);

  String _createPlainTextPrompt(String text) {
    return """
    Aşağıdaki PDF metnini analiz et. Her öğrenci için bulduğun TÜM verileri tek bir satıra, aralarına "|" işareti koyarak yaz. Her öğrenci yeni bir satırda olmalı.
    
    İSTENEN SÜTUN SIRALAMASI (Bu sırayı asla değiştirme):
    Öğrenci No|Ad Soyad|Sınıf|Genel Doğru|Genel Yanlış|Genel Net|TYT Puan|Genel Sıra|Sınıf Sıra|Türkçe D|Türkçe Y|Türkçe N|Tarih D|Tarih Y|Tarih N|Coğrafya D|Coğrafya Y|Coğrafya N|Felsefe D|Felsefe Y|Felsefe N|Din D|Din Y|Din N|Mat D|Mat Y|Mat N|Fizik D|Fizik Y|Fizik N|Kimya D|Kimya Y|Kimya N|Biyoloji D|Biyoloji Y|Biyoloji N
    
    KURALLAR:
    - Sadece istenen veriyi, araya "|" koyarak yaz. Başka HİÇBİR ŞEY yazma.
    - Eğer bir veri yoksa veya okunamıyorsa, o alanı boş bırakma, yerine "0" yaz.
    - Sayılardaki virgülleri (,) mutlaka noktaya (.) çevir.
    
    GİRDİ METNİ:
    $text
    """;
  }

  String _createJsonFromPlainTextPrompt(String plainTextData) {
    return """
    Aşağıdaki "|" ile ayrılmış ham veriyi al ve bunu bir JSON dizisine dönüştür. 
    
    JSON YAPISI:
    Her satırı bir JSON nesnesine çevir. Nesne şu alanları içermeli: `studentNumber`, `fullName`, `className`, `totalCorrect`, `totalWrong`, `totalNet`, `score`, `overallRank`, `classRank` ve `lessonResults` adında bir dizi. `lessonResults` dizisi, her ders için `lessonName`, `correct`, `wrong`, `net` alanlarını içeren nesnelerden oluşmalı.
    
    KURALLAR:
    - Çıktın SADECE ve SADECE `application/json` formatında olmalı.
    - Başka HİÇBİR AÇIKLAMA VEYA METİN EKLEME.

    GİRDİ VERİSİ:
    $plainTextData
    """;
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _pickedFile != null;

    return Scaffold(
      appBar: AppBar(title: Text('Deneme Sonuç Analizi', style: GoogleFonts.poppins())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasFile)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(_pickedFile!.name),
                    subtitle: Text('${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB'),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.upload_file),
                label: const Text('PDF Seç'),
              ),
              const SizedBox(height: 20),
              if (hasFile)
                _isProcessing
                    ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_processingStatus, style: GoogleFonts.poppins(fontSize: 16)),
                    ],
                  ),
                )
                    : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: startAnalysis,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Yapay Zeka ile Analiz Et'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}