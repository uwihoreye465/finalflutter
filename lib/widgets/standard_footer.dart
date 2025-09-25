import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../screens/auth/login_screen.dart';
import '../screens/news/news_screen.dart';

class StandardFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemTapped;

  const StandardFooter({
    super.key,
    this.selectedIndex = 0,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              context: context,
              icon: Icons.home,
              label: 'Home',
              index: 0,
              isSelected: selectedIndex == 0,
            ),
            _buildBottomNavItem(
              context: context,
              icon: Icons.person,
              label: 'Login',
              index: 1,
              isSelected: selectedIndex == 1,
            ),
            _buildBottomNavItem(
              context: context,
              icon: Icons.newspaper,
              label: 'News',
              index: 2,
              isSelected: selectedIndex == 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (onItemTapped != null) {
          onItemTapped!(index);
        } else {
          _handleDefaultNavigation(context, index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDefaultNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NewsScreen()),
        );
        break;
    }
  }
}
