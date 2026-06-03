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
  List<SoilResult> _filtered = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  // Filter state
  String _selectedCategory = 'Lahat'; // 'Lahat', 'Angkop', 'Hindi Angkop'
  String _selectedSOM = 'Lahat'; // SOM filter
  bool _showFilters = false;

  final List<String> _somOptions = [
    'Lahat',
    'Highly Sufficient',
    'Sufficient',
    'Slightly Sufficient',
    'Not Sufficient',
  ];

  @override
  void initState() {
    super.initState();
    _loadResults();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _applyFilters();
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filtered = _results.where((r) {
        // Search filter
        final matchSearch =
            query.isEmpty ||
            r.farmName.toLowerCase().contains(query) ||
            r.prediction.toLowerCase().contains(query) ||
            r.date.toLowerCase().contains(query);

        // Suitability category filter
        final matchCategory =
            _selectedCategory == 'Lahat' ||
            (_selectedCategory == 'Angkop' && r.isSuitable) ||
            (_selectedCategory == 'Hindi Angkop' && !r.isSuitable);

        // SOM filter
        final matchSOM =
            _selectedSOM == 'Lahat' ||
            r.prediction.toLowerCase() == _selectedSOM.toLowerCase();

        return matchSearch && matchCategory && matchSOM;
      }).toList();
    });
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
                  final deletedResult = result;
                  await DatabaseHelper.instance.deleteResult(result.id!);
                  Navigator.pop(context);
                  _loadResults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Nabura ang record ni ${result.farmName}"),
                      action: SnackBarAction(
                        label: "UNDO",
                        onPressed: () async {
                          await DatabaseHelper.instance.insertResult(
                            deletedResult,
                          );
                          _loadResults();
                        },
                      ),
                      duration: const Duration(seconds: 4),
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

            // ── Header ──
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
                  const Spacer(),
                  // Filter toggle button
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _showFilters
                            ? const Color(0xFF187B4D)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune,
                            size: 16,
                            color: _showFilters ? Colors.white : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _showFilters
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Hanapin ang farm o resulta...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Suitability Category Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  _buildCategoryChip('Lahat'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Angkop'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Hindi Angkop'),
                ],
              ),
            ),

            // ── SOM Filter (collapsible) ──
            if (_showFilters)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E9E9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOM Classification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _somOptions
                          .map((opt) => _buildSOMChip(opt))
                          .toList(),
                    ),
                  ],
                ),
              ),

            // ── Result Count ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} record${_filtered.length != 1 ? 's' : ''} na nahanap',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // ── Grid ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF187B4D),
                      ),
                    )
                  : _filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildGalleryGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    Color chipColor;
    Color textColor;

    if (!isSelected) {
      chipColor = const Color(0xFFF0F0F0);
      textColor = Colors.black54;
    } else if (label == 'Angkop') {
      chipColor = const Color(0xFF16A34A);
      textColor = Colors.white;
    } else if (label == 'Hindi Angkop') {
      chipColor = const Color(0xFFDC2626);
      textColor = Colors.white;
    } else {
      chipColor = const Color(0xFF187B4D);
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSOMChip(String label) {
    final isSelected = _selectedSOM == label;
    final color = isSelected
        ? const Color(0xFF187B4D)
        : const Color(0xFFEEEEEE);
    final textColor = isSelected ? Colors.white : Colors.black54;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedSOM = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered =
        _searchController.text.isNotEmpty ||
        _selectedCategory != 'Lahat' ||
        _selectedSOM != 'Lahat';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.landscape_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered ? 'Walang nahanap na record' : 'No saved results yet',
            style: const TextStyle(color: Colors.grey),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'Lahat';
                  _selectedSOM = 'Lahat';
                });
                _applyFilters();
              },
              child: const Text(
                'I-clear ang filters',
                style: TextStyle(color: Color(0xFF187B4D)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) => _buildGalleryCard(_filtered[index]),
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

            // ── Suitability Badge ──
            Positioned(
              bottom: 48,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: result.isSuitable
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.isSuitable ? '☕ Angkop' : '⚠️ Hindi Angkop',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ── Delete Button ──
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

  // ── Helpers ──
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
