import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/ai_models.dart';
import '../../services/app_strings.dart';
import '../home/home_screen.dart';

class SymbolRevealScreen extends ConsumerStatefulWidget {
  const SymbolRevealScreen({super.key, required this.result});

  final ReadingResult result;

  @override
  ConsumerState<SymbolRevealScreen> createState() =>
      _SymbolRevealScreenState();
}

class _SymbolRevealScreenState extends ConsumerState<SymbolRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  int _currentIndex = 0;
  bool _finished = false;
  ui.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final bytes = await File(widget.result.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _decodedImage = frame.image);
    _startSequence();
  }

  Future<void> _startSequence() async {
    if (widget.result.symbols.isEmpty) {
      setState(() => _finished = true);
      return;
    }
    await _revealController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    if (_currentIndex < widget.result.symbols.length - 1) {
      setState(() => _currentIndex++);
      _startSequence();
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final symbols = widget.result.symbols;
    final currentSymbol = symbols.isNotEmpty ? symbols[_currentIndex] : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _decodedImage == null
                    ? const Center(child: CircularProgressIndicator())
                    : AspectRatio(
                        aspectRatio:
                            _decodedImage!.width / _decodedImage!.height,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(widget.result.imagePath),
                                fit: BoxFit.cover,
                              ),
                              if (!_finished && currentSymbol != null)
                                AnimatedBuilder(
                                  animation: _revealController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: _SymbolPainter(
                                        symbol: currentSymbol,
                                        progress: _revealController.value,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: _finished
                      ? Text(
                          widget.result.conclusion,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.warmCream,
                          ),
                        )
                      : (currentSymbol == null
                          ? const SizedBox.shrink()
                          : AnimatedBuilder(
                              animation: _revealController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _revealController.value,
                                  child: Text(
                                    currentSymbol.phrase,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.warmCream,
                                    ),
                                  ),
                                );
                              },
                            )),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_finished)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(ref.tr('back_to_home')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  _SymbolPainter({required this.symbol, required this.progress});

  final ReadingSymbol symbol;
  final double progress;

  Path _buildSmoothPath(Size size) {
    final path = Path();
    if (symbol.points.length < 3) return path;

    final pts = symbol.points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final current = pts[i];
      final next = pts[i + 1];
      final midPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midPoint.dx, midPoint.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (symbol.points.length < 3) return;

    final fullPath = _buildSmoothPath(size);
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final drawLength = metric.length * progress;
    final partialPath = metric.extractPath(0, drawLength);

    final glowPaint = Paint()
      ..color = AppColors.antiqueGold.withValues(alpha: 0.45 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(partialPath, glowPaint);

    final linePaint = Paint()
      ..color = AppColors.antiqueGold.withValues(alpha: progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(partialPath, linePaint);

    if (progress > 0.01 && progress < 1.0) {
      final tangent = metric.getTangentForOffset(drawLength);
      if (tangent != null) {
        final sparkPaint = Paint()
          ..color = AppColors.warmCream.withValues(alpha: 0.9);
        canvas.drawCircle(tangent.position, 4, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.symbol != symbol;
  }
}
