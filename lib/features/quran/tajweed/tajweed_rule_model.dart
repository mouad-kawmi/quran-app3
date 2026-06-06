import 'package:flutter/material.dart';

class TajweedRuleModel {
  final String id;
  final String title;
  final String shortDescription;
  final String detailedExplanation;
  final String exampleWord;
  final Color color;
  final String category;

  const TajweedRuleModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.detailedExplanation,
    required this.exampleWord,
    required this.color,
    required this.category,
  });
}
