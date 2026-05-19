import 'package:flutter/material.dart';
import 'som_classifier.dart';
import 'ph_classifier.dart';
import 'result_page.dart';

class LoadingScreen extends StatefulWidget {
  final String imagePath;
  const LoadingScreen({super.key, required this.imagePath});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final Classifier _somClassifier = Classifier();
  final PhClassifier _phClassifier = PhClassifier();

  String _statusText = 'Analyzing soil sample...';

  @override
  void initState() {
    super.initState();
    _runClassification();
  }

  Future<void> _runClassification() async {
    try {
      // ── Step 1: SOM — tapos muna bago pumunta sa pH ──
      _updateStatus('Analyzing SOM level...');
      await _somClassifier.load();
      final somResult = await _somClassifier.classify(widget.imagePath);
      _somClassifier.dispose(); // ← dispose agad para malaya ang memory
      await Future.delayed(const Duration(seconds: 2));

      // ── Step 2: pH — separate, hindi sabay sa SOM ──
      _updateStatus('Analyzing pH level...');
      await _phClassifier.load();
      final phResult = await _phClassifier.classify(widget.imagePath);
      _phClassifier.dispose();
      await Future.delayed(const Duration(seconds: 2));

      // ── Step 3: Finalizing ──
      _updateStatus('Finalizing results...');
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            imagePath: widget.imagePath,
            prediction: somResult['label'] ?? 'Unknown',
            confidence: somResult['confidence'] ?? '0.0',
            phLevel: phResult['phValue'] ?? '0',
            phStatus: _formatPhStatus(phResult['label'] ?? ''),
            phConfidence: phResult['confidence'] ?? '0.0',
            date: _getFormattedDate(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Classification error: $e')));
      Navigator.pop(context);
    }
  }

  void _updateStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  String _formatPhStatus(String rawLabel) {
    final cleaned = rawLabel.trim().toLowerCase();

    switch (cleaned) {
      case 'ph3':
        return 'Strongly Acidic (0-3)';
      case 'ph4':
      case 'ph5':
      case 'ph6':
        return 'Weakly Acidic (4-6.9)';
      case 'ph7':
        return 'Neutral (7)';
      default:
        return 'Weakly Acidic (4-6.9)'; // ← pansamantala, force return para makita kung logic na ang prob
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]}. ${now.day} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
