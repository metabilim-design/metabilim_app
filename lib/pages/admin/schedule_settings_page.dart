import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  // Her bir zaman dilimi için bir controller
  late List<TextEditingController> _weekdayControllers;
  late List<TextEditingController> _saturdayControllers;

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  @override
  void dispose() {
    for (var controller in _weekdayControllers) {
      controller.dispose();
    }
    for (var controller in _saturdayControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Firestore'dan mevcut saatleri yükler
  Future<void> _loadTimes() async {
    try {
      final doc = await _firestore.collection('settings').doc('schedule_times').get();

      List<String> weekdayTimes = List.generate(10, (index) => '00:00-00:00'); // Varsayılan
      List<String> saturdayTimes = List.generate(5, (index) => '00:00-00:00'); // Varsayılan

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('weekdayTimes')) {
          weekdayTimes = List<String>.from(data['weekdayTimes']);
        }
        if (data.containsKey('saturdayTimes')) {
          saturdayTimes = List<String>.from(data['saturdayTimes']);
        }
      }

      _weekdayControllers = weekdayTimes.map((time) => TextEditingController(text: time)).toList();
      _saturdayControllers = saturdayTimes.map((time) => TextEditingController(text: time)).toList();

    } catch (e) {
      // Hata durumunda boş listelerle başlat
      _weekdayControllers = List.generate(10, (_) => TextEditingController());
      _saturdayControllers = List.generate(5, (_) => TextEditingController());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saatler yüklenemedi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Yeni saatleri Firestore'a kaydeder
  Future<void> _saveTimes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final List<String> weekdayTimes = _weekdayControllers.map((c) => c.text.trim()).toList();
      final List<String> saturdayTimes = _saturdayControllers.map((c) => c.text.trim()).toList();

      await _firestore.collection('settings').doc('schedule_times').set({
        'weekdayTimes': weekdayTimes,
        'saturdayTimes': saturdayTimes,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etüt saatleri başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydederken hata oluştu: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Hafta İçi Etüt Saatleri (10 Adet)'),
            const SizedBox(height: 8),
            ...List.generate(10, (index) => _buildTimeTextField(
              controller: _weekdayControllers[index],
              label: '${index + 1}. Etüt Saati',
            )),
            const SizedBox(height: 24),
            _buildSectionTitle('Cumartesi Etüt Saatleri (5 Adet)'),
            const SizedBox(height: 8),
            ...List.generate(5, (index) => _buildTimeTextField(
              controller: _saturdayControllers[index],
              label: '${index + 1}. Etüt Saati',
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveTimes,
        icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Icon(Icons.save_outlined),
        label: const Text('Değişiklikleri Kaydet'),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildTimeTextField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Bu alan boş bırakılamaz.';
          }
          final regex = RegExp(r'^\d{2}:\d{2}-\d{2}:\d{2}$');
          if (!regex.hasMatch(value.trim())) {
            return "Lütfen 'SS:DD-SS:DD' formatını kullanın.";
          }
          return null;
        },
      ),
    );
  }
}