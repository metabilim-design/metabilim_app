import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'give_books_page.dart'; // Yeni sayfa eklendi

class ConfirmUploadPage extends StatefulWidget {
  final List<File> imageFiles;
  const ConfirmUploadPage({super.key, required this.imageFiles});

  @override
  State<ConfirmUploadPage> createState() => _ConfirmUploadPageState();
}

class _ConfirmUploadPageState extends State<ConfirmUploadPage> {
  bool _isProcessing = false;

  Future<void> _processImagesWithAI() async {
    if (widget.imageFiles.isEmpty) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

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
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    try {
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null) {
        throw Exception('API Anahtarı bulunamadı.');
      }

      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);

      // GÜNCELLENMİŞ PROMPT BAŞLANGICI
      final prompt = """Aşağıdaki metin, bir ders kitabının içindekiler kısmından alınmıştır. Bu metni analiz ederek yalnızca ana konuların başlıklarını ve bunlara karşılık gelen sayfa numaralarını çıkar.

İşlemin adımları ve kurallar şunlar olmalıdır:

1.  **Ana Konu Başlıklarını Belirle:** Ana konu başlıkları genellikle 'ÜNİTE', 'BÖLÜM' gibi kelimelerle veya kalın, büyük fontlu yazılarla başlar. Ancak bu her zaman geçerli olmayabilir. Ana konu başlıkları, genellikle alt başlıkları olan ve bir dersin ana ünitesini temsil eden metinlerdir. "Test", "Kazanım Testi", "Uygulama Testi", "Nefes Açar", "Zihin Açar", "Cevap Anahtarları" gibi ifadeler içeren satırları ve bu satırların sayfa numaralarını **göz ardı et**.

2.  **Alt Başlıkları ve Ek Bilgileri Göz Ardı Et:** Ana başlıkların altında yer alan daha küçük fontlu alt başlıkları veya 'Sayfa [6-13]', '80 dk / 2 gün' gibi ek bilgileri dikkate alma. Sadece ana başlığı ve başlık sonundaki sayfa numarasını ayır. Eğer bir başlığın sayfa aralığı varsa (örneğin "Sayfa [6-13]"), başlangıç sayfasını (bu örnekte 6) kullan. Eğer tek bir sayfa numarası varsa, onu kullan.

3.  **Çıktı Formatı:** Çıktıyı, her bir konunun bir satırda olduğu ve "Konu Başlığı : Sayfa Numarası" formatında olduğu düz bir metin olarak hazırla. Bu format, projenizdeki mevcut sisteme kolayca entegre edilebilir bir yapı sağlayacaktır.

4.  **Sıralama:** Çıkardığın konu başlıklarını, sayfa numaralarına göre küçükten büyüğe doğru sırala.

5.  **Özel Durumlar:**
    * **Birden Fazla Sütun:** Eğer metin, sol ve sağ olmak üzere iki sütun halinde ise, her iki sütundaki ana konu başlıklarını da ayrı ayrı işle. Ancak, çıktıyı sayfa numarasına göre sıraladığın için zaten doğru düzene girecektir.
    * **Yanlış OCR Okumaları:** Bazen metinlerdeki noktalı çizgiler veya sayfa numaraları yanlış okunabilir. Bu gibi durumlarda metnin genel bağlamına göre en mantıklı sonucu üretmeye çalış. Örneğin, bir başlıkta nokta nokta sonrası gelen sayfa numarasını doğru şekilde ayırmaya odaklan.

---
**Girdi Metni:**
$fullText

**Çıktı Formatı (yalnızca JSON):**
[{"konu": "Konu Adı", "sayfa": "Sayfa Numarası"}]
""";
// GÜNCELLENMİŞ PROMPT SONU

      final response = await model.generateContent([Content.text(prompt)]);

      final cleanResponse = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> parsedData = jsonDecode(cleanResponse);

      if (mounted) {
        setState(() => _isProcessing = false);
        _showResultDialog(parsedData);
      }
    } catch (e) {
      print("Yapay Zeka Hatası: $e");
      if (mounted) {
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
              Navigator.of(context).pop();
              // Yeni sayfaya yönlendirme ve veriyi aktarma
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => GiveBooksPage(topics: results),
              ));
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
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat'))],
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