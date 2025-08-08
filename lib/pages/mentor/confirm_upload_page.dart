import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ConfirmUploadPage extends StatefulWidget {
  final List<File> imageFiles;
  const ConfirmUploadPage({super.key, required this.imageFiles});

  @override
  State<ConfirmUploadPage> createState() => _ConfirmUploadPageState();
}

class _ConfirmUploadPageState extends State<ConfirmUploadPage> {
  bool _isProcessing = false;

  // Cihaz üzerinde OCR yapar, sonra metni Gemini AI'ye yollayıp işler
  Future<void> _processImagesWithAI() async {
    if (widget.imageFiles.isEmpty) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    // 1. Adım: Cihaz üzerinde OCR ile ham metni oku
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String fullText = "";
    for (final imageFile in widget.imageFiles) {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      fullText += "${recognizedText.text}\n";
    }
    textRecognizer.close();

    if (fullText.trim().isEmpty) {
      _showErrorDialog("Fotoğraflardan metin okunamadı.");
      if(mounted) setState(() => _isProcessing = false);
      return;
    }

    // 2. Adım: Gemini Yapay Zekasına gönder ve sonucu al
    try {
      // .env dosyasından API anahtarını yükle
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null) {
        throw Exception('API Anahtarı bulunamadı. Projenin ana klasöründeki .env dosyasını kontrol et.');
      }

      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      final prompt = "Aşağıdaki bir kitabın içindekiler sayfası metnidir. Bu metni analiz et ve bana her bir konu başlığı ile başlangıç sayfa numarasını içeren bir JSON listesi döndür. Sadece JSON formatında, başka hiçbir ek metin olmadan cevap ver. Konu başlıklarından '(Test ...)' gibi kısımları temizle. JSON formatı şöyle olsun: [{\"konu\": \"Konu Adı\", \"sayfa\": \"Sayfa Numarası\"}]. Metin: \n$fullText";

      final response = await model.generateContent([Content.text(prompt)]);

      // Gelen cevabı temizle ve JSON'a çevir
      final cleanResponse = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> parsedData = jsonDecode(cleanResponse);

      if(mounted) {
        setState(() => _isProcessing = false);
        _showResultDialog(parsedData);
      }

    } catch (e) {
      print("Yapay Zeka Hatası: $e");
      if(mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog("Metin işlenirken bir hata oluştu: ${e.toString()}");
      }
    }
  }

  void _showResultDialog(List<dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İşlenen Konular (${results.length} adet)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              // Gelen verinin Map formatında ve beklenen anahtarlara sahip olduğunu kontrol edelim.
              final item = results[index] as Map<String, dynamic>;
              final konu = item['konu'] ?? 'Konu bulunamadı';
              final sayfa = item['sayfa'] ?? 'Sayfa yok';
              return ListTile(
                title: Text(konu.toString()),
                trailing: Text("Sayfa: ${sayfa.toString()}"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Bu veriyi alıp TYT/AYT formuna yönlendir
              Navigator.of(context).pop();
            },
            child: const Text('Onayla ve Devam Et'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat')) ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.imageFiles.length} Sayfa Seçildi'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.imageFiles.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(widget.imageFiles[index], fit: BoxFit.cover),
                );
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Yapay zeka analiz ediyor...',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : _processImagesWithAI,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text('Yapay Zeka ile Ayrıştır', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}