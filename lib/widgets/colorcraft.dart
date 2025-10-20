import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class Colorcraft extends StatelessWidget {
  final Color colorSeed;
  const Colorcraft({super.key, required this.colorSeed});

  static Map<Color, String> colorNameMap = {
    Colors.red: 'red',
    Colors.blue: 'blue',
    Colors.green: 'green',
    Colors.yellow: 'yellow',
    Colors.orange: 'orange',
    Colors.purple: 'purple',
    Colors.grey: 'grey',
    Colors.teal: 'teal',
    Colors.lime: 'lime',
  };

  Future<void> _changeTheme(BuildContext context) async {
    String? colorName = colorNameMap[colorSeed];
    if (colorName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('colorSeed', colorName);
      themeColorNotifier.value = colorSeed;
      Fluttertoast.showToast(msg: '主题色已切换为 $colorName');
    } else {
      debugPrint('Color not found in map!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: colorSeed);
    return GestureDetector(
      onTap: () => _changeTheme(context),
      child: Container(
        width: 65,
        height: 65,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.primary),
          color: scheme.primaryContainer,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: ArcPainter(
                    color: scheme.primary,
                    startAngle: 90,
                    sweepAngle: 180,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: ArcPainter(
                    color: scheme.secondary,
                    startAngle: -90,
                    sweepAngle: 90,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: ArcPainter(
                    color: scheme.tertiary,
                    startAngle: 0,
                    sweepAngle: 90,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  const ArcPainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(
      rect,
      startAngle * math.pi / 180,
      sweepAngle * math.pi / 180,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
