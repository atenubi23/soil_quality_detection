import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'cam_open.dart';
import 'list_view.dart';
import 'database_helper.dart';
import 'result_page.dart';
import 'profile.dart';
import 'guidelines_page.dart'; // ← Idagdag ito

class HomeScreenPage extends StatefulWidget {
  final int initialIndex;
  const HomeScreenPage({super.key, this.initialIndex = 0});

  @override
  State<HomeScreenPage> createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  late int _selectedIndex;
  final GlobalKey<_HomeViewState> _homeKey = GlobalKey<_HomeViewState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeKey.currentState?.refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // --- Top Branding Section ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: screenWidth,
                height: topSectionHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35.66),
                    bottomRight: Radius.circular(35.66),
                  ),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/image_10.png',
                      width: screenWidth,
                      height: topSectionHeight * 0.9,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: topSectionHeight * 0.25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo_1.png',
                              width: screenWidth * 0.25,
                              height: screenHeight * 0.04,
                              fit: BoxFit.contain,
                            ),
                            const Text(
                              'Rise & Brew',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 10,
                              ),
                              child: Text(
                                "Hi! Let's keep your goals blooming today.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Guidelines Button (top left) ──
                    Positioned(
                      top: 44,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GuidelinesPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    // ── Profile Icon (top right) ──
                    Positioned(
                      top: 44,
                      right: 16,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                          _homeKey.currentState?.refreshData();
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Main Content Area ---
            Positioned(
              top: topSectionHeight - 20,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.015),
                    SvgPicture.asset(
                      'assets/line_6.svg',
                      width: screenWidth * 0.34,
                      height: 3,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          HomeView(key: _homeKey),
                          const Center(child: Text("Ready to Scan")),
                          const ListViewWidget(),
                        ],
                      ),
                    ),

                    // --- Navigation Bar ---
                    Container(
                      width: screenWidth,
                      height: screenHeight * 0.105,
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            Icons.home,
                            'Home',
                            0,
                            screenWidth,
                            screenHeight,
                          ),
                          _buildNavItem(
                            Icons.camera_alt,
                            'Cam',
                            1,
                            screenWidth,
                            screenHeight,
                          ),
                          _buildNavItem(
                            Icons.menu_book,
                            'List',
                            2,
                            screenWidth,
                            screenHeight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    double sw,
    double sh,
  ) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () async {
        if (index == 1) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CamOpen()),
          );
          setState(() => _selectedIndex = 0);
          _homeKey.currentState?.refreshData();
        } else {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            _homeKey.currentState?.refreshData();
          }
        }
      },
      child: Container(
        width: sw * 0.32,
        height: sh * 0.11,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Container(
                width: sw * 0.2,
                height: 4,
                color: const Color(0xFF187B4D),
              )
            else
              const SizedBox(height: 4),
            const Spacer(),
            Icon(
              icon,
              size: 26,
              color: isActive ? const Color(0xFF187B4D) : Colors.black54,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.black : Colors.black54,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// HOME VIEW
// ─────────────────────────────────────────
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<SoilResult> _recentResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    final all = await DatabaseHelper.instance.getAllResults();
    if (mounted) {
      setState(() {
        _recentResults = all.take(3).toList();
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF187B4D)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recents',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: _recentResults.isEmpty
              ? const Center(
                  child: Text(
                    'No records found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentResults.length,
                  itemBuilder: (context, index) {
                    final result = _recentResults[index];
                    final predColor = _getPredictionColor(result.prediction);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFFE8E9E9)),
                      ),
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultPage(
                                imagePath: result.imagePath,
                                prediction: result.prediction,
                                confidence: result.confidence.toString(),
                                phLevel: result.phLevel.toString(),
                                phStatus: result.phStatus ?? "Stable",
                                phConfidence:
                                    result.phConfidence?.toString() ?? '0.0',
                                date: result.date,
                                farmName: result.farmName,
                                isReadOnly: true,
                              ),
                            ),
                          );
                          refreshData();
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: predColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.grass, color: predColor),
                        ),
                        title: Text(
                          result.farmName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'SOM: ${result.prediction}\npH: ${result.phLevel}\n${result.date}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
