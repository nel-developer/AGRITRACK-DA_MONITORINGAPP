import 'package:flutter/material.dart';
import '../theme/da_colors.dart';
import '../theme/responsive_helper.dart';

/// BottomNavBar
///
/// 3 tabs: Home | Data | Profile
/// White rounded-top card at the bottom of the screen.

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int               currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Container(
      decoration: const BoxDecoration(
        color: DAColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color:      Color(0x18000000),
            blurRadius: 16,
            offset:     Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top:    r.scale(12),
        bottom: r.scale(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon:     Icons.home_rounded,
            label:    'Home',
            selected: currentIndex == 0,
            onTap:    () => onTap(0),
            r:        r,
          ),
          _NavItem(
            icon:     Icons.storage_rounded,
            label:    'Data',
            selected: currentIndex == 1,
            onTap:    () => onTap(1),
            r:        r,
          ),
          _NavItem(
            icon:     Icons.person_rounded,
            label:    'Profile',
            selected: currentIndex == 2,
            onTap:    () => onTap(2),
            r:        r,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.r,
  });

  final IconData         icon;
  final String           label;
  final bool             selected;
  final VoidCallback     onTap;
  final ResponsiveHelper r;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DAColors.greenMid : DAColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: r.scale(72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.scale(28), color: color),
            SizedBox(height: r.scale(4)),
            Text(
              label,
              style: TextStyle(
                fontSize:   r.scaleFont(10),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color:      color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}