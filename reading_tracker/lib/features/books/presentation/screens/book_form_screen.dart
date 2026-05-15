import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';
import '../providers/books_provider.dart';

class BookFormScreen extends ConsumerStatefulWidget {
  const BookFormScreen({super.key});

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final book = Book(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      author: _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
      pages: _pagesController.text.trim().isEmpty
          ? null
          : int.tryParse(_pagesController.text.trim()),
      status: BookStatus.pending,
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
    );

    await ref.read(booksProvider.notifier).addBook(book);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _TitleField(controller: _titleController),
              const SizedBox(height: 16),
              _AuthorField(controller: _authorController),
              const SizedBox(height: 16),
              _PagesField(controller: _pagesController),
              const SizedBox(height: 32),
              _SaveButton(isSaving: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Campos ───────────────────────────────────────────────
class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Title *',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        return null;
      },
    );
  }
}

class _AuthorField extends StatelessWidget {
  const _AuthorField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Author',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _PagesField extends StatelessWidget {
  const _PagesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Pages',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final pages = int.tryParse(value);
          if (pages == null || pages <= 0) {
            return 'Enter a valid number of pages';
          }
        }
        return null;
      },
    );
  }
}

// ── Botón guardar ────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    );
  }
}
