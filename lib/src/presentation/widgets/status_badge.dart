import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SUCCESS':
      case 'COMPLETED':
        bgColor = const Color(0xFFD8EFEC); // KiteTone.success bg
        fgColor = const Color(0xFF0C6B62); // KiteTone.success fg
        break;
      case 'PARTIAL':
      case 'PENDING':
      case 'WARNING':
        bgColor = const Color(0xFFFBEFD6); // KiteTone.warning bg
        fgColor = const Color(0xFF8A5A0B); // KiteTone.warning fg
        break;
      case 'UNPAID':
      case 'CANCELLED':
      case 'DANGER':
      case 'ERROR':
        bgColor = const Color(0xFFFBE7DA); // KiteTone.danger bg
        fgColor = const Color(0xFFB03D0B); // KiteTone.danger fg
        break;
      default:
        bgColor = const Color(0xFFf1f5f9); // Slate 100
        fgColor = const Color(0xFF475569); // Slate 600
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fgColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
