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
  final ScrollController _scrollController = ScrollController();

  // Filter / sort state
  String _selectedCategory = 'Lahat';
  String _selectedSOM = 'Lahat';
  String _selectedPH = 'Lahat'; // NEW: pH range filter
  bool _sortNewest = true; // NEW: sort direction
  bool _showFilters = false;

  // How many cards are rendered at once (lazy-render window)
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  final List<String> _somOptions = [
    'Lahat',
    'Highly Sufficient',
    'Sufficient',
    'Slightly Sufficient',
    'Not Sufficient',
  ];

  // pH range labels mapped to (min, max) inclusive
  final Map<String, (double, double)> _phRanges = {
    'Lahat': (0, 14),
    'Acidic\n<6.0': (0, 5.99),
    'Optimal\n6.0–7.0': (6.0, 7.0),
    'Alkaline\n>7.0': (7.01, 14),
  };

  @override
  void initState() {
    super.initState();
    _loadResults();
    _searchController.addListener(_applyFilters);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Lazy-render: extend visible window as user scrolls near bottom
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (_visibleCount < _filtered.length) {
        setState(
          () => _visibleCount = (_visibleCount + _pageSize).clamp(
            0,
            _filtered.length,
          ),
        );
      }
    }
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
    final (phMin, phMax) = _phRanges[_selectedPH] ?? (0.0, 14.0);

    List<SoilResult> list = _results.where((r) {
      // --- Search ---
      final matchSearch =
          query.isEmpty ||
          r.farmName.toLowerCase().contains(query) ||
          r.prediction.toLowerCase().contains(query) ||
          r.date.toLowerCase().contains(query);

      // --- Suitability ---
      final matchCategory =
          _selectedCategory == 'Lahat' ||
          (_selectedCategory == 'Angkop' && r.isSuitable) ||
          (_selectedCategory == 'Hindi Angkop' && !r.isSuitable);

      // --- SOM ---
      final matchSOM =
          _selectedSOM == 'Lahat' ||
          r.prediction.toLowerCase() == _selectedSOM.toLowerCase();

      // --- pH range ---
      final ph = double.tryParse(r.phLevel) ?? -1;
      final matchPH = _selectedPH == 'Lahat' || (ph >= phMin && ph <= phMax);

      return matchSearch && matchCategory && matchSOM && matchPH;
    }).toList();

    // --- Sort by date ---
    list.sort((a, b) {
      // Try ISO or "Month Day, Year" style; fall back to string compare
      final da = _parseDate(a.date);
      final db = _parseDate(b.date);
      return _sortNewest ? db.compareTo(da) : da.compareTo(db);
    });

    setState(() {
      _filtered = list;
      _visibleCount = _pageSize; // reset window on any filter change
    });
  }

  /// Flexible date parser — extend as needed to match your stored format.
  DateTime _parseDate(String raw) {
    // Try standard formats
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {}
    // e.g. "June 3, 2025" or "Jun 3, 2025"
    try {
      return _parsePrettyDate(raw.trim());
    } catch (_) {}
    // Last resort: lexicographic (works for YYYY-MM-DD strings)
    return DateTime(0);
  }

  DateTime _parsePrettyDate(String s) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final clean = s.replaceAll(',', '').split(RegExp(r'\s+'));
    if (clean.length < 3) throw const FormatException('short');
    final m = months[clean[0].toLowerCase().substring(0, 3)];
    if (m == null) throw const FormatException('month');
    final d = int.parse(clean[1]);
    final y = int.parse(clean[2]);
    return DateTime(y, m, d);
  }

  // ── DELETE LOGIC ──
  void _confirmDelete(SoilResult result) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Delete Record?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Sigurado ka bang gusto mong burahin ang record para sa ${result.farmName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                if (result.id != null) {
                  final deleted = result;
                  await DatabaseHelper.instance.deleteResult(result.id!);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadResults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nabura ang record ni ${result.farmName}'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () async {
                          await DatabaseHelper.instance.insertResult(deleted);
                          _loadResults();
                        },
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
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
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Image avatar
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
            // SOM row
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
            // pH row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _phIcon(double.tryParse(result.phLevel) ?? 7),
                    size: 18,
                    color: _phColor(double.tryParse(result.phLevel) ?? 7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pH ${result.phLevel} — ${result.phStatus}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Suitability row
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

  // ── BUILD ──
  @override
  Widget build(BuildContext context) {
    final activeFilterCount = _countActiveFilters();

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

                  // Sort toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() => _sortNewest = !_sortNewest);
                      _applyFilters();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortNewest
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortNewest ? 'Pinakabago' : 'Pinakamatanda',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Filter toggle button (with badge when filters active)
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
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
                                color: _showFilters
                                    ? Colors.white
                                    : Colors.black54,
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
                        if (activeFilterCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$activeFilterCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
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

            // ── Suitability Tabs ──
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

            // ── Collapsible Filter Panel ──
            if (_showFilters)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
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
                    // SOM filter
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
                          .map((o) => _buildSOMChip(o))
                          .toList(),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 12),

                    // pH range filter — NEW
                    Row(
                      children: const [
                        Icon(
                          Icons.water_drop,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'pH Range',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _phRanges.keys
                          .map((k) => _buildPHChip(k))
                          .toList(),
                    ),

                    // Clear filters link
                    if (activeFilterCount > 0) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _clearAllFilters,
                        child: const Text(
                          'I-clear lahat ng filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF187B4D),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Count + Sort indicator ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} record${_filtered.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  // Show how many are currently rendered when list is long
                  if (_filtered.length > _pageSize) ...[
                    const Text(
                      ' · ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Showing ${_visibleCount.clamp(0, _filtered.length)} of ${_filtered.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
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

  // ── How many non-default filters are on ──
  int _countActiveFilters() {
    int count = 0;
    if (_selectedCategory != 'Lahat') count++;
    if (_selectedSOM != 'Lahat') count++;
    if (_selectedPH != 'Lahat') count++;
    return count;
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = 'Lahat';
      _selectedSOM = 'Lahat';
      _selectedPH = 'Lahat';
    });
    _applyFilters();
  }

  // ── Chips ──
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
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSOM = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF187B4D) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // NEW: pH range chip
  Widget _buildPHChip(String label) {
    final isSelected = _selectedPH == label;
    Color activeColor;
    if (label.contains('Acidic')) {
      activeColor = const Color(0xFFDC2626); // red
    } else if (label.contains('Alkaline')) {
      activeColor = const Color(0xFF7C3AED); // purple
    } else if (label.contains('Optimal')) {
      activeColor = const Color(0xFF2563EB); // blue
    } else {
      activeColor = const Color(0xFF187B4D); // green = Lahat
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPH = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          // Remove newlines for the chip display
          label.replaceAll('\n', ' '),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    final isFiltered =
        _searchController.text.isNotEmpty ||
        _selectedCategory != 'Lahat' ||
        _selectedSOM != 'Lahat' ||
        _selectedPH != 'Lahat';

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
              onPressed: _clearAllFilters,
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

  // ── Gallery Grid ──
  // Only renders up to _visibleCount items; ScrollController extends the window
  Widget _buildGalleryGrid() {
    final slice = _filtered.take(_visibleCount).toList();

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: slice.length + (_visibleCount < _filtered.length ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == slice.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF187B4D),
              ),
            ),
          );
        }
        return _buildGalleryCard(slice[index]);
      },
    );
  }

  Widget _buildGalleryCard(SoilResult result) {
    final Color predColor = _getPredictionColor(result.prediction);
    final String predEmoji = _getPredictionEmoji(result.prediction);
    final ph = double.tryParse(result.phLevel) ?? 7.0;

    return GestureDetector(
      onTap: () => _showResultPopup(context, result),
      onLongPress: () => _confirmDelete(result),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                // ── Image ──
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
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

                // ── Info Panel ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farm name
                      Text(
                        result.farmName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // SOM prediction
                      Row(
                        children: [
                          Text(predEmoji, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
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
                      const SizedBox(height: 2),
                      // pH mini-bar
                      _buildPHBar(ph),
                      const SizedBox(height: 2),
                      // Date
                      Text(
                        result.date,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Suitability Badge (bottom-left of image) ──
            Positioned(
              bottom: 58,
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
                  result.isSuitable ? '☕ Angkop' : '⚠️ Hindi',
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

  // NEW: compact pH mini-bar shown in each card
  Widget _buildPHBar(double ph) {
    final color = _phColor(ph);
    final fraction = (ph / 14.0).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(Icons.water_drop, size: 9, color: color),
        const SizedBox(width: 3),
        Text(
          'pH ${ph.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──
  Color _phColor(double ph) {
    if (ph < 6.0) return const Color(0xFFDC2626); // acidic → red
    if (ph <= 7.0) return const Color(0xFF2563EB); // optimal → blue
    return const Color(0xFF7C3AED); // alkaline → purple
  }

  IconData _phIcon(double ph) {
    if (ph < 6.0) return Icons.water_drop_outlined;
    if (ph <= 7.0) return Icons.water_drop;
    return Icons.water;
  }

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
