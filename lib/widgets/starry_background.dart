import 'package:flutter/material.dart';

class StarryBackground extends StatelessWidget {
  const StarryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF6D8), Color(0xFFFDE2B1), Color(0xFFFFFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(color: Color(0xFFFFD166), size: 180),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _GlowCircle(color: Color(0xFFB8F1E0), size: 160),
          ),
          Positioned(
            top: 260,
            left: 220,
            child: _GlowCircle(color: Color(0xFFBFD7FF), size: 120),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
