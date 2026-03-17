import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Finder'),
      ),
      body: const Center(
        child: Text(
          'Yakin akaryakit istasyonlarini bul',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
