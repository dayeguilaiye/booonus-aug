import 'package:flutter/material.dart';

class PointsChip extends StatelessWidget {
  final int points;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const PointsChip({
    super.key,
    required this.points,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPointsColor(context);
    final backgroundColor = color.withOpacity(0.1);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            points >= 0 ? Icons.add : Icons.remove,
            size: (fontSize ?? 14) + 2,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            points.abs().toString(),
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPointsColor(BuildContext context) {
    if (points > 0) {
      return Colors.green;
    } else if (points < 0) {
      return Colors.red;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

class PriceChip extends StatelessWidget {
  final int price;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const PriceChip({
    super.key,
    required this.price,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = primaryColor.withOpacity(0.1);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.diamond,
            size: (fontSize ?? 14) + 2,
            color: primaryColor,
          ),
          const SizedBox(width: 2),
          Text(
            price.toString(),
            style: TextStyle(
              color: primaryColor,
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
