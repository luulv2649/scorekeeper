import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Màu điểm: âm = xanh (tốt), dương = đỏ (xấu), 0 = mặc định
Color scoreColor(int score, ColorScheme cs) {
  if (score < 0) return Colors.green.shade600;
  if (score > 0) return Colors.red.shade600;
  return cs.onSurface;
}

/// Màu theo index người chơi
Color playerColor(int index) {
  const colors = [
    Color(0xFF1565C0), // blue
    Color(0xFFC62828), // red
    Color(0xFF2E7D32), // green
    Color(0xFFE65100), // orange
  ];
  return colors[index % 4];
}

/// Format ngày giờ ngắn
String shortDate(DateTime dt) => DateFormat('dd/MM/yy').format(dt);

String shortDateTime(DateTime dt) => DateFormat('dd/MM/yy HH:mm').format(dt);

/// Tên viết tắt (chữ cái đầu)
String initials(String name) =>
    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
