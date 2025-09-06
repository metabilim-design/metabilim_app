import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
      updateStatus("PDF'ten metinler çıkarılıyor...");
      final pdfText = await _extractTextFromPdf(_pickedFile!.bytes!);

      updateStatus("Yapay zeka verileri ayıklıyor ve tablo oluşturuyor...");
      final markdownTable = await _analyzeAndCreateTable(pdfText);

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ExamResultsPreviewPage(
            markdownContent: markdownTable,
            examName: _pickedFile!.name,
          ),
        ));
      }
    } catch (e) {
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

  Future<String> _analyzeAndCreateTable(String text) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('GEMINI_API_KEY bulunamadı.');

    final model = GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );

    // --- EN İYİ YAKLAŞIM: ADIM ADIM TALİMAT PROMPT'U ---
    final prompt = _createFullDetailsTablePrompt(text);
    final response = await model.generateContent([Content.text(prompt)]);

    if (response.text == null || response.text!.trim().isEmpty) {
      throw Exception("Yapay zeka bir sonuç tablosu üretemedi.");
    }
    debugPrint("--- OLUŞTURULAN TABLO ---\n${response.text}");
    return response.text!;
  }

  void updateStatus(String status) => setState(() => _processingStatus = status);

  // --- EN İYİ YAKLAŞIM: ADIM ADIM TALİMAT PROMPT'U ---
  String _createFullDetailsTablePrompt(String text) {
    return """
    Senin görevin, bir PDF'ten çıkarılmış karmaşık metni analiz edip, bunu hatasız bir Markdown tablosuna dönüştürmektir.

    ADIM 1: SÜTUNLARI ANLA
    Oluşturacağın tablonun sütunları tam olarak şunlar olmalı ve bu sırada olmalı:
    `Sıra`|`Öğrenci Adı`|`Sınıf`|`Toplam D`|`Toplam Y`|`Toplam Net`|`TYT Puanı`|`Sınıf S.`|`Türkçe D`|`Türkçe Y`|`Türkçe N`|`Mat. D`|`Mat. Y`|`Mat. N`|`Fizik D`|`Fizik Y`|`Fizik N`|`Kimya D`|`Kimya Y`|`Kimya N`|`Biyo. D`|`Biyo. Y`|`Biyo. N`|`Tarih D`|`Tarih Y`|`Tarih N`|`Coğ. D`|`Coğ. Y`|`Coğ. N`|`Fel. D`|`Fel. Y`|`Fel. N`|`Din D`|`Din Y`|`Din N`

    ADIM 2: ÖĞRENCİ VERİLERİNİ TEK TEK İŞLE
    Metni satır satır oku ve her bir öğrenciye ait veriyi bul.
    - **EN ÖNEMLİ KURAL:** Bazen iki öğrencinin verisi (isimleri, notları vb.) tek bir satır bloğunda birleşmiş olabilir. Bu blokları GÖRDÜĞÜN ANDA, onları mantıksal olarak iki ayrı öğrenci satırına BÖL. ASLA birleşik bırakma.
    - Her öğrenci için ADIM 1'deki sütunlara karşılık gelen verileri yerleştir.
    - Eğer bir veri yoksa veya eksikse, o hücreye "0" yaz.

    ADIM 3: TABLOYU OLUŞTUR VE ÇIKTI VER
    - Tüm öğrencileri işledikten sonra, sonucu Markdown tablosu olarak oluştur.
    - Tüm ondalık sayılarda virgül (,) yerine nokta (.) kullandığından emin ol.
    - Çıktı olarak SADECE ve SADECE Markdown tablosunu ver. Başka tek bir kelime bile yazma.

    İşte analiz etmen gereken metin:
    $text
    """;
  }

  @override
  Widget build(BuildContext context) {
    // UI kodunda herhangi bir değişiklik yok.
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