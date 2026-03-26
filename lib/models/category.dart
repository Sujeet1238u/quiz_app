// lib/models/category.dart

import 'package:flutter/material.dart';

class QuizCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int questionCount;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.questionCount,
  });
}
