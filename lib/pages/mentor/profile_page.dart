import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Bu sayfa tam ekran açılacağı için kendi AppBar'ı olabilir.
    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Profili')),
      body: const Center(
        child: Text('Mentor Profil Sayfası'),
      ),
    );
  }
}