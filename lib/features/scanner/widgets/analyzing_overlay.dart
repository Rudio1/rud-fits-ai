import 'dart:io';

import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class AiMealPhotoScanOverlay extends StatefulWidget {
  const AiMealPhotoScanOverlay({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<AiMealPhotoScanOverlay> createState() => _AiMealPhotoScanOverlayState();
}

class _AiMealPhotoScanOverlayState extends State<AiMealPhotoScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;
  late final Animation<double> _scanCurve;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _scanCurve = CurvedAnimation(
      parent: _scan,
      curve: MotionTokens.inOut,
    );
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          widget.imageFile,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.28),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final w = constraints.maxWidth;
              const bandH = 112.0;
              return AnimatedBuilder(
                animation: _scanCurve,
                builder: (context, child) {
                  final t = _scanCurve.value;
                  final top = t * (h + bandH) - bandH * 0.65;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: top,
                        height: bandH,
                        child: CustomPaint(
                          size: Size(w, bandH),
                          painter: const _ScanBeamPainter(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const SizedBox(
                      width: 140,
                      height: 3,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Analisando foto…',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanBeamPainter extends CustomPainter {
  const _ScanBeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.primaryGreen.withValues(alpha: 0.08),
          AppColors.primaryGreen.withValues(alpha: 0.38),
          AppColors.primaryGreen.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    const coreH = 3.0;
    final cy = size.height / 2 - coreH / 2;
    final coreRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy, size.width, coreH),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(
      coreRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      coreRect,
      Paint()..color = AppColors.primaryGreen.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
