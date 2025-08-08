import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ConfirmUploadPage extends StatefulWidget {
  final List<File> imageFiles;
  const ConfirmUploadPage({super.key, required this.imageFiles});

  @override
  State<ConfirmUploadPage> createState() => _ConfirmUploadPageState();
}

class _ConfirmUploadPageState extends State<ConfirmUploadPage> {
  bool _isProcessing = false;
  String _processedText = "";

  // Cihaz üzerinde görüntüden metin okuyan fonksiyon
  Future<void> _processImagesOnDevice() async {
    if (widget.imageFiles.isEmpty) return;

    setState(() => _isProcessing = true);

    // Metin tanıyıcıyı oluştur
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    String fullText = "";

    // Her bir fotoğraf dosyası için metin tanıma yap
    for (final imageFile in widget.imageFiles) {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      fullText += recognizedText.text + "\n";
    }

    textRecognizer.close();

    setState(() {
      _processedText = fullText;
      _isProcessing = false;
    });

    // TODO: Bu _processedText'i alıp, bir önceki prototipteki gibi
    // konu ve sayfa aralıklarına ayıran DART kodunu yazacağız.
    // Sonrasında da TYT/AYT formuna yönlendireceğiz.

    // Şimdilik sonucu göstermek için bir dialog açalım
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metin Tanıma Sonucu'),
        content: SingleChildScrollView(child: Text(_processedText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
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
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              itemCount: widget.imageFiles.length,
              itemBuilder: (context, index) {
                return Image.file(widget.imageFiles[index], fit: BoxFit.cover);
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Metin okunuyor, lütfen bekleyin...'),
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
                ),
                onPressed: _processImagesOnDevice,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text('Yazıları Oku', style: GoogleFonts.poppins(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }
}