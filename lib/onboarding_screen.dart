// onboarding_screen.dart
import 'package:flutter/material.dart';
import 'onboarding_page.dart'; // ← palitan ito

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.eco,
      color: const Color(0xFF187B4D),
      title: 'Maligayang pagdating sa Rise & Brew!',
      description:
          'Ang app na ito ay tumutulong sa mga magsasaka na suriin ang kalidad ng lupa para sa mas magandang ani ng kape.',
    ),
    _OnboardingData(
      icon: Icons.camera_alt_outlined,
      color: const Color(0xFF2563EB),
      title: 'Kumuha ng larawan ng lupa',
      description:
          'Pindutin ang "Cam" tab para kumuha ng larawan ng iyong soil sample. Siguraduhing maliwanag ang lugar at nakapokus ang camera sa lupa.',
    ),
    _OnboardingData(
      icon: Icons.science_outlined,
      color: const Color(0xFFD97706),
      title: 'Makita ang resulta ng pagsusuri',
      description:
          'Awtomatikong susuriin ng app ang SOM (Soil Organic Matter) at pH level ng lupa batay sa kulay nito. Angkop lamang para sa loam soil.',
    ),
    _OnboardingData(
      icon: Icons.menu_book_outlined,
      color: const Color(0xFF7C3AED),
      title: 'I-save at suriin ang mga resulta',
      description:
          'Makikita sa "List" tab ang lahat ng iyong mga naunang pagsusuri. Maaari kang mag-filter, maghanap, at mag-edit ng mga record.',
    ),
  ];

  // ← Ngayon papunta sa OnboardingPage, hindi na HomeScreenPage
  void _goToProfileSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToProfileSetup, // ← updated
                child: const Text(
                  'Laktawan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 56, color: page.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF187B4D)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next / Susunod button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLastPage
                      ? _goToProfileSetup // ← updated
                      : () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF187B4D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastPage ? 'Susunod →' : 'Susunod',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
