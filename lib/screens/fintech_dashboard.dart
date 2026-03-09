import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernFintechDashboard extends StatefulWidget {
  const ModernFintechDashboard({super.key});

  @override
  State<ModernFintechDashboard> createState() => _ModernFintechDashboardState();
}

class _ModernFintechDashboardState extends State<ModernFintechDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Colors
    const Color bgColor = Color(0xFF0D0D0F);
    const Color cardColor = Color(0xFF1C1C1E);
    const Color primaryNavy = Color(0xFF0A1F44);
    const Color accentBlue = Color(0xFF1E5691);
    const Color secondaryGrey = Color(0xFF2C2C2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // 1) Top Header Section - Premium Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryNavy, Color(0xFF142E5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$42,650.00',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward,
                              color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '+4.2%',
                            style: GoogleFonts.outfit(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'This month profit',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(140),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // 2) Circular Action Buttons - Matte Style
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                          Icons.send_rounded, 'Send', primaryNavy),
                      _buildActionButton(
                          Icons.wallet_rounded, 'Receive', secondaryGrey),
                      _buildActionButton(Icons.history_toggle_off_rounded,
                          'Bills', secondaryGrey),
                      _buildActionButton(
                          Icons.apps_rounded, 'More', secondaryGrey),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 3) Main Content Cards - Transaction History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'See all',
                        style: GoogleFonts.outfit(
                          color: accentBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Column(
                      children: [
                        _buildTransactionItem('Netflix', 'Monthly Plan',
                            '-\$15.99', Icons.movie_outlined),
                        Divider(color: Colors.white.withAlpha(15), height: 1),
                        _buildTransactionItem('Dribbble', 'Pro Plan',
                            '-\$12.00', Icons.sports_basketball_rounded),
                        Divider(color: Colors.white.withAlpha(15), height: 1),
                        _buildTransactionItem('Upwork', 'Project Payment',
                            '+\$1,200.00', Icons.work_outline_rounded,
                            isPositive: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4) Service Grid Section - Elevated Style
                  Text(
                    'Quick Services',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildServiceCard(
                          'Statistics', Icons.analytics_rounded, accentBlue),
                      _buildServiceCard('Savings', Icons.savings_rounded,
                          Colors.purpleAccent),
                      _buildServiceCard('Cards', Icons.credit_card_rounded,
                          Colors.orangeAccent),
                      _buildServiceCard('Invest', Icons.show_chart_rounded,
                          Colors.tealAccent),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 5) Bottom Navigation Bar - Minimalist
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(15), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.compass_calibration_rounded, 'Explore'),
            _buildNavItem(1, Icons.account_balance_rounded, 'Wallet'),
            _buildNavItem(2, Icons.bar_chart_rounded, 'Report'),
            _buildNavItem(3, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    bool isPrimary = color == const Color(0xFF0A1F44);
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isPrimary ? color : const Color(0xFF1C1C1E),
            shape: BoxShape.circle,
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withAlpha(30)
                  : Colors.white.withAlpha(10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withAlpha(180),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
      String title, String subtitle, String amount, IconData icon,
      {bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(
              color: isPositive ? Colors.greenAccent : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF1E5691)
                : Colors.white.withAlpha(60),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected
                  ? const Color(0xFF1E5691)
                  : Colors.white.withAlpha(60),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
