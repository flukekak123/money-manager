import 'package:flutter/material.dart';

import '../../domain/entities.dart';
import '../theme.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.radius = 20});

  final Category category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Icon(
        iconFromCodePoint(category.iconCodePoint),
        color: color,
        size: radius * 1.1,
      ),
    );
  }
}
