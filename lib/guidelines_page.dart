import 'package:flutter/material.dart';

class GuidelinesPage extends StatelessWidget {
  const GuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF187B4D),
        foregroundColor: Colors.white,
        title: const Text(
          'Mga Gabay sa Paggamit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildGuidelineCard(
            number: '1',
            icon: Icons.science_outlined,
            title: 'Para sa mas tumpak na resulta',
            content:
                'Ang soil detector ay sumusukat ng Soil Organic Matter (SOM) at pH level batay sa kulay ng lupa. Para sa mas maaasahan at mas tumpak na pagsusuri, loam soil lamang ang inirerekomendang gamitin sa kasalukuyan.',
          ),
          const SizedBox(height: 12),
          _buildGuidelineCard(
            number: '2',
            icon: Icons.apps_outlined,
            title: 'Pagkilala sa mga pangunahing bahagi ng app',
            content:
                'Ang app ay may tatlong pangunahing tab:\n\n• Home – Dito makikita ang iyong mga pinakabagong soil sample at resulta ng pagsusuri.\n\n• Camera – Gamitin ito upang kumuha ng larawan ng soil sample para sa pagsusuri.\n\n• Listahan (Gallery) – Dito nakaimbak at makikita ang lahat ng iyong mga naunang soil sample at resulta.',
          ),
          const SizedBox(height: 12),
          _buildGuidelineCard(
            number: '3',
            icon: Icons.camera_alt_outlined,
            title: 'Tamang pagkuha ng larawan ng lupa',
            content:
                'Para sa mas tumpak na resulta, siguraduhing:\n\n• Maliwanag ang paligid o sapat ang ilaw.\n• Nakapokus nang maayos ang camera sa soil sample.\n• Iwasan ang mga anino o bagay na maaaring makaapekto sa kulay ng lupa.\n• Tiyaking malinaw at hindi malabo ang nakuhang larawan.\n• Ilagay ang soil sample sa isang patag at malinis na lugar bago kumuha ng larawan.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF187B4D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF187B4D).withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF187B4D), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Basahin ang mga sumusunod na gabay para sa mas epektibong paggamit ng app.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF187B4D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard({
    required String number,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E9E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF187B4D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: const Color(0xFF187B4D), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE8E9E9)),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
