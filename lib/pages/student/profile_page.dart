import 'package:flutter/material.dart';
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: const Center(child: Text('Profil Sayfası')),
    );
  }
}