import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/features/scanner/screens/confirm_meal_screen.dart';
import 'package:rud_fits_ai/features/scanner/widgets/analyzing_overlay.dart';
import 'package:rud_fits_ai/features/scanner/widgets/scanner_frame.dart';
import 'package:rud_fits_ai/services/meal_log_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _initError;
  bool _analyzing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: const [],
    );
    _initFuture = _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initFuture = _initCamera();
      setState(() {});
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _initError = 'Nenhuma câmera encontrada no aparelho.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setFlashMode(FlashMode.off);
      setState(() {
        _controller = controller;
        _initError = null;
      });
    } on CameraException catch (e) {
      setState(() {
        if (e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessRestricted' ||
            e.code == 'CameraAccessDeniedWithoutPrompt') {
          _initError =
              'Permita o acesso à câmera nas configurações para escanear suas refeições.';
        } else {
          _initError = 'Não foi possível iniciar a câmera. Tente novamente.';
        }
      });
    } catch (_) {
      setState(() => _initError = 'Erro inesperado ao iniciar a câmera.');
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      AppHaptics.selection();
      setState(() => _flashMode = next);
    } catch (_) {}
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _analyzing) {
      return;
    }

    AppHaptics.selection();
    setState(() => _analyzing = true);

    try {
      final picture = await controller.takePicture();
      await _analyzeImage(File(picture.path));
    } catch (_) {
      if (!mounted) return;
      await AppHaptics.error();
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao capturar a foto.')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_analyzing) return;

    AppHaptics.selection();

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (picked == null || !mounted) return;

      setState(() => _analyzing = true);
      await _analyzeImage(File(picked.path));
    } catch (_) {
      if (!mounted) return;
      await AppHaptics.error();
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao abrir a galeria.')),
      );
    }
  }

  Future<void> _analyzeImage(File image) async {
    final analyzed = await MealLogApiService.analyzePhoto(image);

    if (!mounted) return;

    if (!analyzed.ok) {
      await AppHaptics.error();
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(analyzed.error ?? 'Erro ao analisar a foto.'),
        ),
      );
      return;
    }

    final estimated = await MealLogApiService.estimateDetectedFoodsNutrition(
      analyzed.meal!,
    );

    if (!mounted) return;

    if (!estimated.ok) {
      await AppHaptics.error();
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estimated.error ?? 'Erro ao estimar a nutrição.'),
        ),
      );
      return;
    }

    await AppHaptics.success();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      AppTransitions.slideFromRight(
        page: ConfirmMealScreen(meal: estimated.meal!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initError != null)
            _CameraErrorView(message: _initError!, onRetry: () {
              setState(() {
                _initError = null;
                _initFuture = _initCamera();
              });
            })
          else
            FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                final controller = _controller;
                if (controller == null || !controller.value.isInitialized) {
                  return const _CameraLoading();
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _FullscreenPreview(controller: controller),
                    const _ScannerScrim(),
                    const Center(child: ScannerFrame()),
                  ],
                );
              },
            ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  flashMode: _flashMode,
                  onClose: () => Navigator.of(context).maybePop(),
                  onToggleFlash:
                      _controller?.value.isInitialized == true && !_analyzing
                          ? _toggleFlash
                          : null,
                ),
                const Spacer(),
                _Hint(),
                const SizedBox(height: 16),
                _CaptureBar(
                  enabled: _controller?.value.isInitialized == true &&
                      _initError == null &&
                      !_analyzing,
                  onCapture: _capture,
                  onGallery: _analyzing ? null : _pickFromGallery,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_analyzing) const AnalyzingOverlay(),
        ],
      ),
    );
  }
}

class _FullscreenPreview extends StatelessWidget {
  const _FullscreenPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    final scale = size.aspectRatio * (previewSize.height / previewSize.width);

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width / (scale > 0 ? scale : 1),
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _ScannerScrim extends StatelessWidget {
  const _ScannerScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onClose,
    required this.onToggleFlash,
    required this.flashMode,
  });

  final VoidCallback onClose;
  final VoidCallback? onToggleFlash;
  final FlashMode flashMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          _IconButton(icon: Icons.close_rounded, onTap: onClose),
          const Spacer(),
          _IconButton(
            icon: flashMode == FlashMode.torch
                ? Icons.flash_on_rounded
                : Icons.flash_off_rounded,
            onTap: onToggleFlash,
            active: flashMode == FlashMode.torch,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.primaryGreen.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.45),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Posicione a refeição no quadro',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.enabled,
    required this.onCapture,
    required this.onGallery,
  });

  final bool enabled;
  final VoidCallback onCapture;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _GalleryButton(onTap: onGallery),
            ),
          ),
          GestureDetector(
            onTap: enabled ? onCapture : null,
            child: AnimatedContainer(
              duration: MotionTokens.fast,
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.3),
                  width: 4,
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: MotionTokens.fast,
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled
                        ? AppColors.primaryGreen
                        : AppColors.primaryGreen.withValues(alpha: 0.4),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: enabled ? 0.55 : 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.25 : 0.1),
            ),
          ),
          child: Icon(
            Icons.photo_library_rounded,
            color: Colors.white.withValues(alpha: enabled ? 0.95 : 0.4),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.no_photography_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Câmera indisponível',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
