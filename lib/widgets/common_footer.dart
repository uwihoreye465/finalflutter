import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CommonFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CommonFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterItem(
            icon: Icons.home,
            label: 'Home',
            index: 0,
            isSelected: currentIndex == 0,
          ),
          _buildFooterItem(
            icon: Icons.person,
            label: 'Login',
            index: 1,
            isSelected: currentIndex == 1,
          ),
          _buildFooterItem(
            icon: Icons.newspaper,
            label: 'News',
            index: 2,
            isSelected: currentIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
