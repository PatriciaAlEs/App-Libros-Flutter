import 'package:flutter/material.dart';

class BooksListScreen extends StatelessWidget {
  const BooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Books')),
      body: const Center(
        child: Text('FUNCIONA'),
      ),
    );
  }
}