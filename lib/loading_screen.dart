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
      // ── Step 1: SOM ──
      _updateStatus('Analyzing SOM level...');
      final somResults = await Future.wait([
        _somClassifier.load().then(
          (_) => _somClassifier.classify(widget.imagePath),
        ),
        Future.delayed(const Duration(seconds: 2)),
      ]);
      final somResult = somResults[0] as Map<String, dynamic>;

      // ── Step 2: pH ──
      _updateStatus('Analyzing pH level...');
      final phResults = await Future.wait([
        _phClassifier.load().then(
          (_) => _phClassifier.classify(widget.imagePath),
        ),
        Future.delayed(const Duration(seconds: 2)),
      ]);
      final phResult = phResults[0] as Map<String, dynamic>;

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
            phLevel: phResult['phValue'] ?? '7.0',
            phStatus: _formatPhStatus(phResult['label'] ?? ''),
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
    } finally {
      _somClassifier.dispose();
      _phClassifier.dispose();
    }
  }

  void _updateStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  String _formatPhStatus(String rawLabel) {
    switch (rawLabel.trim()) {
      case 'Ph3':
        return 'Strongly Acidic (0-3)';
      case 'Ph4':
        return 'Weakly Acidic (4-6.9)';
      case 'Ph5':
        return 'Weakly Acidic (4-6.9)';
      case 'Ph6':
        return 'Weakly Acidic (4-6.9)';
      case 'Ph7':
        return 'Neutral (7)';
      default:
        return rawLabel;
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
