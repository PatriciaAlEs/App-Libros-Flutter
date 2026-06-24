import 'package:flutter/material.dart';

import 'readpp_sentry.dart';

class SentryValidationScreen extends StatefulWidget {
  const SentryValidationScreen({super.key});

  @override
  State<SentryValidationScreen> createState() => _SentryValidationScreenState();
}

class _SentryValidationScreenState extends State<SentryValidationScreen> {
  bool _isSending = false;
  bool _sent = false;

  Future<void> _sendValidationException() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _sent = false;
    });

    await ReadPpSentry.captureValidationException();

    if (!mounted) return;
    setState(() {
      _isSending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sentry validation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _isSending ? null : _sendValidationException,
                child: Text(_isSending ? 'Sending...' : 'Capture exception'),
              ),
              if (_sent) ...[
                const SizedBox(height: 16),
                Text(
                  'Validation exception captured.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
