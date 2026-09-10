import 'package:flutter/material.dart';

class FileItemModel {
  final String id;
  final String name;
  final String category;
  final String size;
  final String updatedAt;
  final IconData icon;
  final Color color;
  final bool isFolder;

  const FileItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.updatedAt,
    required this.icon,
    required this.color,
    this.isFolder = false,
  });
}
