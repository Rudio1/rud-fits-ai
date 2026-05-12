import 'package:flutter/material.dart';

import 'package:rud_fits_ai/themes/themes.dart';

class ScannerFrame extends StatefulWidget {
  const ScannerFrame({super.key, this.size = 280});

  final double size;

  @override
  State<ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<ScannerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.25 + (_pulse.value * 0.35);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.85),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: glow),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              const _Corner(alignment: Alignment.topLeft),
              const _Corner(alignment: Alignment.topRight),
              const _Corner(alignment: Alignment.bottomLeft),
              const _Corner(alignment: Alignment.bottomRight),
            ],
          ),
        );
      },
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.all(-2),
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.primaryGreen, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.primaryGreen, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.primaryGreen, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.primaryGreen, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight:
                isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
            bottomLeft:
                !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            bottomRight:
                !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
