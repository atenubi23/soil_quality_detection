import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'homescreen_page.dart';

class ListViewWidget extends StatefulWidget {
  const ListViewWidget({super.key});

  @override
  State<ListViewWidget> createState() => _ListViewWidgetState();
}

class _ListViewWidgetState extends State<ListViewWidget> {
  List<SoilResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final results = await DatabaseHelper.instance.getAllResults();
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  // ── DELETE LOGIC ──
  void _confirmDelete(SoilResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Delete Record?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Sigurado ka bang gusto mong burahin ang record para sa ${result.farmName}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                if (result.id != null) {
                  // 1. Itago muna ang record sa memory bago i-delete
                  final deletedResult = result;
                  final deletedIndex = _results.indexOf(result);

                  // 2. I-delete sa Database
                  await DatabaseHelper.instance.deleteResult(result.id!);

                  // 3. I-update ang UI
                  Navigator.pop(context);
                  _loadResults();

                  // 4. Ipakita ang SnackBar na may Undo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Nabura ang record ni ${result.farmName}"),
                      action: SnackBarAction(
                        label: "UNDO",
                        onPressed: () async {
                          // Ibalik ang record sa database
                          await DatabaseHelper.instance.insertResult(
                            deletedResult,
                          );
                          _loadResults(); // I-refresh ang listahan
                        },
                      ),
                      duration: const Duration(
                        seconds: 4,
                      ), // May 4 seconds ang user para mag-undo
                    ),
                  );
                }
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Result Popup ──
  void _showResultPopup(BuildContext context, SoilResult result) {
    final Color predColor = _getPredictionColor(result.prediction);
    final String predEmoji = _getPredictionEmoji(result.prediction);
    final double confidence = double.tryParse(result.confidence) ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: const Color(0xFFD9D9D9),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  result.imagePath.isNotEmpty &&
                      File(result.imagePath).existsSync()
                  ? Image.file(File(result.imagePath), fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              result.farmName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              result.date,
              style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
            ),
            const SizedBox(height: 16),
            // SOM Prediction Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: predColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: predColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(predEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.prediction,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: predColor,
                          ),
                        ),
                        const Text(
                          'SOM Classification',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: predColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // pH Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.water_drop,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pH Level: ${result.phLevel} — ${result.phStatus}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Suitability
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.isSuitable
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result.isSuitable
                    ? '☕ Angkop para sa kape'
                    : '⚠️ Hindi pa angkop sa kape',
                style: TextStyle(
                  color: result.isSuitable
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreenPage(initialIndex: 0),
                      ),
                      (route) => false,
                    ),
                  ),
                  const Text(
                    'Field Records',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF187B4D),
                      ),
                    )
                  : _results.isEmpty
                  ? _buildEmptyState()
                  : _buildGalleryGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_outlined, size: 64, color: Colors.grey.shade300),
          const Text(
            'No saved results yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildGalleryCard(_results[index]),
    );
  }

  Widget _buildGalleryCard(SoilResult result) {
    final Color predColor = _getPredictionColor(result.prediction);
    final String predEmoji = _getPredictionEmoji(result.prediction);

    return GestureDetector(
      onTap: () => _showResultPopup(context, result),
      onLongPress: () => _confirmDelete(result),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        result.imagePath.isNotEmpty &&
                            File(result.imagePath).existsSync()
                        ? Image.file(
                            File(result.imagePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.farmName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(predEmoji, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              result.prediction,
                              style: TextStyle(
                                fontSize: 10,
                                color: predColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'pH ${result.phLevel} • ${result.date}',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Delete Icon Button
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => _confirmDelete(result),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS (Same as your logic) ---
  Color _getPredictionColor(String prediction) {
    switch (prediction.toLowerCase()) {
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

  String _getPredictionEmoji(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'highly sufficient':
        return '🟢';
      case 'sufficient':
        return '🔵';
      case 'slightly sufficient':
        return '🟡';
      case 'not sufficient':
        return '🔴';
      default:
        return '⚪';
    }
  }
}
