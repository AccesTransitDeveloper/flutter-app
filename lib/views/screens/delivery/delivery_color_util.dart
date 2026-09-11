import 'package:flutter/material.dart';

/// Parse a server-driven hex color string (e.g. "#FF5722", "FF5722",
/// "#80FF5722") into a [Color]. Returns null for empty/invalid input.
Color? hexToColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h'; // add opaque alpha
  if (h.length != 8) return null;
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}
