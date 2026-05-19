// result_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'list_view.dart';
import 'homescreen_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultPage extends StatefulWidget {
  final String imagePath;
  final String prediction;
  final String confidence;
  final String phLevel;
  final String phStatus;
  final String date;
  final String farmName;
  final bool isReadOnly;
  final String phConfidence;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    required this.phLevel,
    required this.phStatus,
    required this.date,
    this.isReadOnly = false,
    this.farmName = 'Amadeo Farm : Field North',
    this.phConfidence = '0.0',
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _isSaving = false;
  bool _isSaved = false;
  String _farmName = 'Amadeo Farm : Field North';

  @override
  void initState() {
    super.initState();
    _loadFarmName();
  }

  Future<void> _loadFarmName() async {
    if (widget.isReadOnly) {
      setState(() => _farmName = widget.farmName);
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _farmName = prefs.getString('farm_name') ?? widget.farmName;
      });
    }
  }

  // ─────────────────────────────────────────
  // SOM HELPERS
  // ─────────────────────────────────────────
  Color _getPredictionColor() {
    switch (widget.prediction.toLowerCase()) {
      case 'highly sufficient':
        return const Color(0xFF16A34A);
      case 'sufficient':
        return const Color(0xFF2563EB);
      case 'slightly sufficient':
        return const Color(0xFFD97706);
      case 'not sufficient':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  // ── Replaced emoji with Widget circle ──
  Widget _buildColorDot(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ── Tag active logic: only one is active ──
  String _getActiveTag() {
    final som = widget.prediction.trim().toLowerCase();
    final ph = double.tryParse(widget.phLevel.trim()) ?? -1;
    final phGood = ph >= 5.0 && ph <= 7.0;

    if (som == 'not sufficient') return 'Bad';

    // Lahat ng sufficient variants + phGood = Good
    final somGood = som == 'highly sufficient' || som == 'sufficient';

    if (somGood && phGood) return 'Good';

    return 'Neutral';
  }

  bool _isGoodForCoffee() {
    final som = widget.prediction.trim().toLowerCase();
    final ph = double.tryParse(widget.phLevel.trim()) ?? -1;
    final phGood = ph >= 5.0 && ph <= 7.0;

    final somGood = som == 'highly sufficient' || som == 'sufficient';
    return somGood && phGood;
  }

  // ─────────────────────────────────────────
  // pH HELPERS
  // ─────────────────────────────────────────
  Color _getPhColor() {
    switch (widget.phStatus) {
      case 'Strongly Acidic (0-3)':
        return const Color(0xFFDC2626);
      case 'Weakly Acidic (4-6.9)':
        return const Color(0xFFD97706);
      case 'Neutral (7)':
        return const Color(0xFF16A34A);
      case 'Strongly Alkaline (7.1-14)':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey;
    }
  }

  // ─────────────────────────────────────────
  // SUCCESS DIALOG
  // ─────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF4CAF50),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Field Recorded Successfully!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF09090B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The soil scan result has been saved to your field records.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF71717A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ListViewWidget()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF187B4D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View List',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SAVE TO FIELD
  // ─────────────────────────────────────────
  Future<void> _saveToField() async {
    if (_isSaved) return;
    setState(() => _isSaving = true);

    try {
      final result = SoilResult(
        farmName: _farmName,
        prediction: widget.prediction,
        confidence: widget.confidence,
        phLevel: widget.phLevel,
        phStatus: widget.phStatus,
        phConfidence: widget.phConfidence,
        date: widget.date,
        imagePath: widget.imagePath,
        isSuitable: _isGoodForCoffee(),
      );

      await DatabaseHelper.instance.insertResult(result);

      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final predColor = _getPredictionColor();
    final phColor = _getPhColor();
    final double confidenceValue = double.tryParse(widget.confidence) ?? 0.0;
    final bool goodForCoffee = _isGoodForCoffee();
    final String activeTag = _getActiveTag();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header / Back ──
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 20, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Main Data Card ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _farmName,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      widget.date,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF71717A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'SOM Level : ${widget.prediction}\npH Level    : ${widget.phLevel} (${widget.phStatus})',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w300,
                                        fontSize: 13,
                                        height: 1.6,
                                        color: Color(0xFF71717A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ── Image Circle ──
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: widget.imagePath.isNotEmpty
                                        ? Image.file(
                                            File(widget.imagePath),
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(50),
                                          bottomRight: Radius.circular(50),
                                        ),
                                      ),
                                      child: Text(
                                        '${confidenceValue.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── SOM Classification Banner ──
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: predColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: predColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // ── Colored dot (replaces emoji) ──
                                _buildColorDot(predColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.prediction,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: predColor,
                                        ),
                                      ),
                                      Text(
                                        'SOM Classification',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: predColor.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ── Confidence % (right side) ──
                                Text(
                                  '${confidenceValue.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: predColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── pH Classification Banner ──
                          // ── pH Classification Banner ──
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: phColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: phColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildColorDot(phColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'pH ${widget.phLevel}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: phColor,
                                        ),
                                      ),
                                      Text(
                                        widget.phStatus,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: phColor.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${widget.phConfidence}%', // ← tama (pH confidence)
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: phColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Coffee Suitability Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: goodForCoffee
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            goodForCoffee
                                ? Icons.coffee
                                : Icons.warning_amber_rounded,
                            color: goodForCoffee
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              goodForCoffee
                                  ? 'Angkop para sa coffee cultivation sa Amadeo'
                                  : 'Hindi pa angkop para sa coffee cultivation',
                              style: TextStyle(
                                color: goodForCoffee
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Buttons ──
                    widget.isReadOnly
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveToField,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF187B4D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          _isSaved
                                              ? 'Saved to Records'
                                              : 'Save to Field',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HomeScreenPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.black : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: active ? Colors.white : const Color(0xFF18181B),
        ),
      ),
    );
  }
}
